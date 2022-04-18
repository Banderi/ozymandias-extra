/* dropsheet.js (C) 2014-present SheetJS -- http://sheetjs.com */
/* Modifications copyright (C) 2017 -- Matthias Findeisen */
/* vim: set ts=2: */
var DropSheet = function DropSheet(opts) {
    if (!opts) opts = {};
    var nullfunc = function() {};
    if (!opts.errors) opts.errors = {};
    if (!opts.errors.badfile) opts.errors.badfile = nullfunc;
    if (!opts.errors.pending) opts.errors.pending = nullfunc;
    if (!opts.errors.failed) opts.errors.failed = nullfunc;
    if (!opts.errors.large) opts.errors.large = nullfunc;
    if (!opts.on) opts.on = {};
    if (!opts.on.workstart) opts.on.workstart = nullfunc;
    if (!opts.on.workend) opts.on.workend = nullfunc;
    if (!opts.on.sheet) opts.on.sheet = nullfunc;
    if (!opts.on.wb) opts.on.wb = nullfunc;

    function getQueryVariable(variable) {
        var query = window.location.search.substring(1);
        var vars = query.split("&");
        for (var i = 0; i < vars.length; i++) {
            var pair = vars[i].split("=");
            if (pair[0] == variable) {
                return pair[1];
            }
        }
        return (false);
    }
    var url = getQueryVariable("url"); // /index.html?url=
    console.log("url: " + url);

    var rABS = typeof FileReader !== 'undefined' && typeof FileReader.prototype !== 'undefined' && typeof FileReader.prototype.readAsBinaryString !== 'undefined';
    var useworker = typeof Worker !== 'undefined';
    var pending = false;

    function fixdata(data) {
        var o = "",
            l = 0,
            w = 10240;
        for (; l < data.byteLength / w; ++l)
            o += String.fromCharCode.apply(null, new Uint8Array(data.slice(l * w, l * w + w)));
        o += String.fromCharCode.apply(null, new Uint8Array(data.slice(o.length)));
        return o;
    }

    function sheetjsw(data, cb, readtype, xls) {
        pending = true;
        opts.on.workstart();
        var scripts = document.getElementsByTagName('script');
        var dropsheetPath;
        for (var i = 0; i < scripts.length; i++) {
            if (scripts[i].src.indexOf('dropsheet') != -1) {
                dropsheetPath = scripts[i].src.split('dropsheet.js')[0];
            }
        }
        var worker = new Worker(dropsheetPath + 'sheetjsw.js');
        worker.onmessage = function(e) {
            switch (e.data.t) {
                case 'ready':
                    break;
                case 'e':
                    pending = false;
                    console.error(e.data.d);
                    break;
                case 'xls':
                case 'xlsx':
                    pending = false;
                    opts.on.workend();
                    cb(JSON.parse(e.data.d), e.data.t);
                    break;
            }
        };
        worker.postMessage({
            d: data,
            b: readtype,
            t: xls ? 'xls' : 'xlsx'
        });
    }

    var last_wb, last_type;

    function to_json(workbook, type) {
        var XL = type.toUpperCase() === 'XLS' ? XLS : XLSX;
        if (useworker && workbook.SSF) XLS.SSF.load_table(workbook.SSF);
        var result = {};
        workbook.SheetNames.forEach(function(sheetName) {
            var roa = XL.utils.sheet_to_row_object_array(workbook.Sheets[sheetName], {
                raw: true
            });
            if (roa.length > 0) result[sheetName] = roa;
        });
        return result;
    }

    function get_columns(sheet, type) {
        var val, rowObject, range, columnHeaders, emptyRow, C;
        if (!sheet['!ref']) return [];
        range = XLS.utils.decode_range(sheet["!ref"]);
        columnHeaders = [];
        for (C = range.s.c; C <= range.e.c; ++C) {
            val = sheet[XLS.utils.encode_cell({
                c: C,
                r: range.s.r
            })];
            if (!val) continue;
            columnHeaders[C] = type.toLowerCase() == 'xls' ? XLS.utils.format_cell(val) : val.v;
        }
        return columnHeaders;
    }

    function choose_sheet(sheetidx) {
        process_wb(last_wb, last_type, sheetidx);
    }

    function process_wb(wb, type, sheetidx) {
        last_wb = wb;
        last_type = type;
        opts.on.wb(wb, type, sheetidx);
        var sheet = wb.SheetNames[sheetidx || 0];
        if (type.toLowerCase() == 'xls' && wb.SSF) XLS.SSF.load_table(wb.SSF);
        var json = to_json(wb, type)[sheet],
            cols = get_columns(wb.Sheets[sheet], type);
        opts.on.sheet(json, cols, wb.SheetNames, choose_sheet);
    }

    function handleDrop(e) {
        var reader = new FileReader();

        var oReq = new XMLHttpRequest();
        oReq.open("GET", url, true);
        oReq.responseType = "arraybuffer";
        oReq.send();

        var bstr;
        oReq.onload = function(e) {
            var arraybuffer = oReq.response;
            var data1 = new Uint8Array(arraybuffer);
            var arr1 = new Array();
            for (var i = 0; i != data1.length; ++i) arr1[i] = String.fromCharCode(data1[i]);
            bstr = arr1.join("");

            var blobRequest = new XMLHttpRequest();
            blobRequest.open("GET", url, true);
            blobRequest.responseType = "blob";
            blobRequest.send();

            var blob1
            blobRequest.onload = function(e) {
                var blobbuffer = blobRequest.response;
                blob1 = blobbuffer;

                reader.onload = function(e) {
                    var data = bstr;
                    var wb, arr, xls;
                    var readtype = {
                        type: rABS ? 'binary' : 'base64'
                    };
                    if (!rABS) {
                        arr = fixdata(data);
                        data = btoa(arr);
                    }
                    xls = [0xd0, 0x3c].indexOf(data.charCodeAt(0)) > -1;
                    if (!xls && arr) xls = [0xd0, 0x3c].indexOf(arr[0].charCodeAt(0)) > -1;
                    if (rABS && !xls && [0x50, 0x09, 0xEF].indexOf(data.charCodeAt(0)) === -1)
                        return opts.errors.badfile();

                    function doit() {
                        try {
                            if (useworker) {
                                sheetjsw(data, process_wb, readtype, xls);
                                return;
                            }
                            if (xls) {
                                wb = XLS.read(data, readtype);
                                process_wb(wb, 'XLS');
                            } else {
                                wb = XLSX.read(data, readtype);
                                process_wb(wb, 'XLSX');
                            }
                        } catch (e) {
                            opts.errors.failed(e);
                        }
                    }

                    if (e.target.result.length > 500000) opts.errors.large(e.target.result.length, function(e) {
                        if (e) doit();
                    });
                    else {
                        doit();
                    }
                };
                if (rABS) reader.readAsBinaryString(blob1);
                else reader.readAsArrayBuffer(blob1);
            }
        }
    };
    handleDrop();
};