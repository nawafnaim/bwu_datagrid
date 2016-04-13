@HtmlImport('app_element.html')
library app_element;

import 'dart:html' as dom;
import 'dart:math' as math;

import 'package:polymer/polymer.dart';
import 'package:web_components/web_components.dart' show HtmlImport;

import 'package:bwu_datagrid/core/core.dart' as core;
import 'package:bwu_datagrid/datagrid/helpers.dart';
import 'package:bwu_datagrid/bwu_datagrid.dart';
import 'package:bwu_datagrid/dataview/dataview.dart';
import 'package:bwu_datagrid_examples/asset/example_style.dart';
import 'package:bwu_datagrid_examples/shared/options_panel.dart';

/// Silence analyzer [exampleStyleSilence], [OptionsPanel]
@PolymerRegister('app-element')
class AppElement extends PolymerElement {
  AppElement.created() : super.created();

  final List<Column> columns = <Column>[];
  Map<String, String> columnFilters = <String, String>{};

  final GridOptions gridOptions = new GridOptions(
      enableCellNavigation: true,
      showHeaderRow: true,
      headerRowHeight: 30,
      explicitInitialization: true);

  math.Random rnd = new math.Random();

  BwuDatagrid grid;
  List<DataItem> data;

  @override
  void attached() {
    super.attached();

    try {
      grid = $['myGrid'];

      for (int i = 0; i < 10; i++) {
        columns.add(new Column(
            id: i.toString(),
            name: new String.fromCharCode('A'.codeUnits[0] + i),
            field: i.toString(),
            width: 60));
      }

      // prepare the data
      data = <DataItem>[];
      for (int i = 0; i < 100; i++) {
        final MapDataItem d =
            new MapDataItem();
        d['id'] = i;
        for (int j = 0; j < columns.length; j++) {
          d[j.toString()] = rnd.nextInt(10);
        }
        data.add(d);
      }

      DataView<core.ItemBase> dataView =
          new DataView<core.ItemBase>();

      grid
          .setup(
              dataProvider: dataView,
              columns: columns,
              gridOptions: gridOptions)
          .then((_) {
        dataView.onBwuRowCountChanged.listen((core.RowCountChanged e) {
          grid.updateRowCount();
          grid.render();
        });

        dataView.onBwuRowsChanged.listen((core.RowsChanged e) {
          grid.invalidateRows(e.changedRows);
          grid.render();
        });

        void filterChangedHandler(dom.Event e) {
          final String columnId = (e.target as dom.Element).dataset['columnId'];
          if (columnId != null) {
            columnFilters[columnId] = (e.target as dom.InputElement).value;
            dataView.refresh();
          }
        }

        grid.onBwuHeaderRowCellRendered.listen((core.HeaderRowCellRendered e) {
          e.node.children.clear();
          String value = columnFilters[e.columnDef.id];
          if (value == null) {
            value = '';
          }
          e.node.append(new dom.TextInputElement()
            ..dataset['columnId'] = e.columnDef.id
            ..value = value
            ..onKeyUp.listen(filterChangedHandler)
            ..onChange.listen(filterChangedHandler));
        });

        grid.init();

        dataView.beginUpdate();
        dataView.items = data;
        dataView.setFilter(filter);
        dataView.endUpdate();
      });
    } on NoSuchMethodError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } on RangeError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } on TypeError catch (e) {
      print('$e\n\n${e.stackTrace}');
    } catch (e) {
      print('$e');
    }
  }

  bool filter(DataItem item, [Object args]) {
    for (final String columnId in columnFilters.keys) {
      if (columnId != null && columnFilters[columnId].isNotEmpty) {
        Column c = grid.getColumns[grid.getColumnIndex(columnId)];
        if (item[c.field].toString() != columnFilters[columnId]) {
          return false;
        }
      }
    }
    return true;
  }
}
