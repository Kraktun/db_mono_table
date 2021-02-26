import 'package:flutter/material.dart';
import 'package:db_mono_table/data_table_rev.dart';
import 'package:db_mono_table/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:db_mono_table/table_object.dart';
import 'package:db_mono_table/http_utils.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

class TablePage extends StatefulWidget {
  static const String ROUTE = 'table-page';
  @override
  _TablePageState createState() => new _TablePageState();
}

class _TablePageState extends State<TablePage> {

  /// Table vars
  // columns
  static final List<String> _columns = TableObject.COLUMNS;
  // list of currently shown elements
  List<TableObject> _dataObjects = [TableObject(elements: List.filled(_columns.length, ""), boxTip: "")];
  // list of all elements, to avoid reconnection to the server to pull the new data.
  // It's updated only when the page is reloaded or a search is performed (not for filters)
  final List<TableObject> _fullObjects = [];
  // sorting mode
  bool _sortAsc = true;
  // sorting column
  int _sortColumnIndex = 0;

  /// Layout vars
  final ScrollController _scrollVertController = ScrollController();
  final ScrollController _scrollHorController = ScrollController();
  final GlobalKey<ScaffoldState> _mainKey = new GlobalKey<ScaffoldState>();
  double _heightScroller = 48;

  /// Search vars
  Icon _searchIcon = Icon(Icons.search);
  Widget _searchTitle = Text("Search");
  final TextEditingController _searchController = TextEditingController();

  /// Filter vars
  // controllers for the filters
  List<TextEditingController> _filterControllers = List.generate(_columns.length, (index) => TextEditingController());
  // text boxes for the filters
  DataRowR _filterBoxes = DataRowR(
    cells: List.filled(_columns.length, DataCellR.empty),
  );

  /// Apply filters to the table
  ///
  /// asynchronously filters all data.
  /// [ignoreCheck] true if you are sure a filter is present/has changed and data should be reloaded
  /// includes sort table after the filter, as it is not guaranteed that the mapping results in a ordered table
  Future<void> _applyFilters(bool ignoreCheck) async {
    if (ignoreCheck || _filterControllers.any((element) => element.text.isNotEmpty)) {
      _dataObjects = _fullObjects.where((obj) => obj.applyFilter(_filterControllers.map((c) => c.text).toList())).toList();
      _sortTable().then((value) => setState(() {}));
    }
  }

  Future<void> _sortTable() async {
    if (_sortAsc)
      _dataObjects.sort((a, b) => tryCompareAsNumber(a.elements[_sortColumnIndex], b.elements[_sortColumnIndex]));
    else
      _dataObjects.sort((a, b) => tryCompareAsNumber(b.elements[_sortColumnIndex], a.elements[_sortColumnIndex]));
  }

  @override
  void initState() {
    super.initState();
    // execute after initial frame is shown
    WidgetsBinding.instance.addPostFrameCallback((_) => {
      // show loading screen
      showLoadingScreen(context),
      // populate table
      _populateTable(false).then((value) =>
        // sort table
      _sortTable().then(
        // remove loading screen
        (v) => Navigator.pop(context)),
      ),
    });
    // add filters listener to the controllers
    _filterControllers.forEach((controller) => {
      controller.addListener(() {
        _applyFilters(true);
      })
    });
    // add controllers to the text fields
    _filterBoxes = DataRowR(
        cells: Iterable<int>.generate(_columns.length).toList().map((idx) => DataCellR(TextField(
          controller: _filterControllers[idx],
          decoration: InputDecoration(
              prefixIcon: Icon(Icons.filter_list, color: Colors.black,),
              hintText: 'Filter'
          ),
        ))).toList()
    );
    // The DraggableScrollbar captures also the horizontal scroll (but displays it as vertical)
    // So we set the height to 0 whenever we are scrolling horizontally and restore it when we scroll vertically
    _scrollHorController.addListener(() {
      if (_heightScroller > 0) {
        setState(() {
          _heightScroller = 0;
        });
      }
    });
    _scrollVertController.addListener(() {
      if (_heightScroller < 48) {
        setState(() {
          _heightScroller = 48;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _filterControllers.forEach((element) => element.dispose());
    super.dispose();
  }

  /// Populate the table with values from the server
  /// useSearch if search function has been used
  Future<void> _populateTable(bool useSearch) async {
    final lists = useSearch ? await getTableData(context, filterText: _searchController.text) : await getTableData(context);
    // populate list of rows so that the setState rebuilds the table with the new values
    _dataObjects = lists;
    _fullObjects.clear();
    _fullObjects.addAll(lists);
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {

    /// Fired when enter is pressed and search was on focus
    void _searchPressed() {
      setState(() {
        // show textfield to input search query
        if (this._searchIcon.icon == Icons.search) {
          this._searchIcon = Icon(Icons.close);
          this._searchTitle = TextField(
            controller: _searchController,
            decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.black,),
                hintText: 'Search...'
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              showLoadingScreen(context);
              // load data filtered from server according to search
              _populateTable(true).then((value) => {
                  // apply local filters
                  _applyFilters(false).then((value) => Navigator.pop(context)),
                  }
              );
            },
          );
        } else {
          // clean search textfield and reload table with all data from server and applies local filters
          showLoadingScreen(context);
          this._searchIcon = Icon(Icons.search);
          this._searchTitle = Text("Search");
          _searchController.clear();
          _populateTable(false).then((value) => {
              // apply local filters
              _applyFilters(false).then((value) => Navigator.pop(context)),
            }
          );
        }
      });
    }

    final table = DataTableR(
      columns:
        _columns.map((e) => DataColumnR(
          label: Text(
            e,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          onSort: (columnIndex, sortAscending) {
            setState(() {
              if (_sortColumnIndex == columnIndex && _sortAsc == sortAscending)
                return;
              _sortColumnIndex = columnIndex;
              _sortAsc = sortAscending;
              showLoadingScreen(context);
              _sortTable().then((value) => Navigator.pop(context));
            });
          },
        ),
        ).toList(),
      rows: [_filterBoxes] + _dataObjects.map((e) => e.toRow()).toList(),
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAsc,
      verticalPadding: [10,10],
    );

    final appBar = AppBar(
      title: _searchTitle,
      leading: IconButton(
        icon: _searchIcon,
        onPressed: _searchPressed,
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.logout,
            color: Colors.black,
          ),
          onPressed: () {
            showLoadingScreen(context);
            logout(context);
          },
        )
      ],
    );

    return MaterialApp(
      title: "Storage Manager",
      home: Scaffold(
        key: _mainKey,
        appBar: appBar,
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: DraggableScrollbar.rrect(
            controller: _scrollVertController,
            heightScrollThumb: _heightScroller,
            child: ListView.builder(
              controller: _scrollVertController,
              itemCount: 1,
              itemBuilder: (context, index) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollHorController,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width,
                    ),
                    child: table, // should be changed with expandable tiles
                  ),
                );
              }
            ),
          ),
        ),
      ),
    );
  }
}