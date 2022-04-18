/* Modifications copyright (C) 2017 -- Matthias Findeisen */
/** drop target **/
var _target = document.getElementById('drop');
/** Spinner **/
var spinner;
var _workstart = function() {
    spinner = new Spinner().spin(_target);
}
var _workend = function() {
    spinner.stop();
}
/** Alerts **/

var _badfile = function() {
    alertify.alert('This file does not appear to be a valid Excel file.', function() {});
};
var _pending = function() {
    alertify.alert('Please wait until the current file is processed.', function() {});
};
var _large = function(len, cb) {
    alertify.confirm("This file is " + len/1000000 + " megabytes and may take a few moments.  Your browser may lock up during this process.", cb);
};
var _failed = function(e) {
    alertify.alert('Failed.', function() {});
};
/** Handsontable magic **/
var boldRenderer = function(instance, td, row, col, prop, value, cellProperties) {
    Handsontable.TextCell.renderer.apply(this, arguments);
    $(td).css({
        'font-weight': 'bold'
    });
};
var $container, $parent, $window, availableWidth, availableHeight;
var calculateSize = function() {
    var offset = $container.offset();
    //availableWidth = Math.max($window.width() - 250, 600);
    //availableHeight = Math.max($window.height() - 250, 400);
    availableWidth = Math.max($window.width() - 100, 200);
    availableHeight = Math.max($window.height() - 100, 200);
};
$(document).ready(function() {
    $container = $("#hot");
    $parent = $container.parent();
    $window = $(window);
    $window.on('resize', calculateSize);
});
/* make the buttons for the sheets */
var make_buttons = function(sheetnames, cb) {
    var $dropdownItems = $('#dropdown-menu').html("");
    sheetnames.forEach(function(s, idx) {
        var button = $('<li>').attr({
            id: idx,
            type: 'text',
            name: 'btn' + idx,
            text: s,
            class: ""
        });
        var $firstSheetActive = $(document.getElementById(0));
        $firstSheetActive.attr('class', 'active');
        button.append('<a>' + s + '</a></li>');
        button.click(function() {
            cb(idx);
            var $firstSheetInactiveAfterClick = $(document.getElementById(0));
            $firstSheetInactiveAfterClick.attr('class', '');
            var $setActive = $(document.getElementById(idx));
            $setActive.attr('class', 'active');
        });
        $dropdownItems.append(button);
    });
};
var _onsheet = function(json, cols, sheetnames, select_sheet_cb) {
    $('#footnote').hide();
    make_buttons(sheetnames, select_sheet_cb);
    calculateSize();
    /* add header row for table */
    if (!json) json = [];
    json.unshift(function(head) {
        var o = {};
        for (i = 0; i != head.length; ++i) o[head[i]] = head[i];
        return o;
    }(cols));
    calculateSize();


    /* showtime! */
    $("#hot").handsontable({
        data: json,
        startRows: 5,
        startCols: 3,
        fixedRowsTop: 1,
        manualColumnResize: true,
        modifyColWidth: function(width, col){
            if(width > 300){
                return 300
            }
        },
        rowHeights: 23,
        rowHeaders: true,
        columns: cols.map(function(x) {
            return {
                data: x
            };
        }),
        colHeaders: cols.map(function(x, i) {
            return XLS.utils.encode_col(i);
            
        }),
        cells: function(r, c, p) {
            if (r === 0) this.renderer = boldRenderer;
        },
        width: function() {
            return availableWidth;
        },
        height: function() {
            return availableHeight;
        },
        stretchH: 'none'
    });
};

DropSheet({
    drop: _target,
    on: {
        workstart: _workstart,
        workend: _workend,
        sheet: _onsheet,
        foo: 'bar'
    },
    errors: {
        badfile: _badfile,
        pending: _pending,
        failed: _failed,
        large: _large,
        foo: 'bar'
    }
})
