"use strict";

function main(reportXml) {
  // get output directory
  var fs = WScript.CreateObject("Scripting.FileSystemObject");
  var dir = fs.getParentFolderName(reportXml);

  // load xml
  var xml = new ActiveXObject("MSXML2.DOMDocument");
  xml.load(reportXml);
  var table = xml.documentElement.getElementsByTagName("Table")[0];
  var rows = table.getElementsByTagName("Row");

  // create mapping for columnNo → columnName
  var columnMapping = [];
  var header = rows[0];
  var headerCells = header.getElementsByTagName("Cell");
  for (var i = 0; i < headerCells.length; i++) {
    var cell = headerCells[i];
    var data = cell.getElementsByTagName("Data")[0];
    var text = data.text;
    columnMapping[i] = text;
  }

  // data structure for storing row data
  function Row(rowData) {
    for (var i = 0; i < rowData.length; i++) {
      var columnName = columnMapping[i];
      this[columnName] = rowData[i];
    }
  }
  Row.prototype.toString = function () {
    var result = [];
    for (var i = 0; i < columnMapping.length; i++) {
      var columnName = columnMapping[i];
      result.push(this[columnName]);
    }
    return result.join(",");
  };

  // read xml data by 1 line, and convert it to object
  var rowObjects = [];
  for (var i = 1; i < rows.length; i++) {
    var row = rows[i];
    var cells = row.getElementsByTagName("Cell");
    var rowData = [];
    for (var j = 0; j < cells.length; j++) {
      var cell = cells[j];
      var data = cell.getElementsByTagName("Data")[0];
      var text = data.text;
      rowData.push(text);
    }
    var rowObject = new Row(rowData);
    rowObjects.push(rowObject);
  }

  // create new file for writing
  var outputPath = dir + "\\report.csv";
  var file = fs.CreateTextFile(outputPath, true, true);

  // write row into output csv file
  file.writeLine(columnMapping.join(","));
  for (var i = 0; i < rowObjects.length; i++) {
    var rowObject = rowObjects[i];
    //WScript.Echo(rowObject.toString());
    // filter 0 trade data
    if (rowObject.Trades != "0") {
      file.writeLine(rowObject.toString());
    }
  }

  file.close();
}

var argc = WScript.Arguments.Count();
if (argc == 0) {
  WScript.Echo("no argument, exit!");
} else {
  var file = WScript.Arguments.Item(0);
  main(file);
}
