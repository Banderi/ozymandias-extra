let main = document.getElementById('main');
let drop = document.getElementById('drop');
let openfile = document.getElementById('openfile');

const to_data = (wb, sheet) => {
  let result = [];
  let ws = wb.Sheets[wb.SheetNames[sheet]];
  let json = XLS.utils.sheet_to_json(ws,{header:1, raw:false});
  //if empty, set dummy array
  if (json.length == 0){
    json.push([]);
  } else {
    // pad max col in a first row
    let max_col = Math.max.apply(null, json.map(x=>{return x.length}));
    let first_col = json[0].length;
    for (let i = 0; i < max_col - first_col ; i++ ) {
        json[0].push("");
    }
  }
  return json;
}

let workbook;
const openSpreadsheetData = bin_data => {
  /* if binary string, read with type 'binary' */
  workbook = XLS.read(bin_data, {type: 'binary', cellDates:true, dateNF:"YYYY-MM-DD"});
  
  //show sheet names
  let tagstr = '<div class="toggle-buttons">';
  for (let i=0;i<workbook.SheetNames.length;i++){
    tagstr +=
    `<label><input type="radio" name="radio-1" ${i == 0 ? `checked` : ``}>
      <span class="button" id="radio-${i}">${workbook.SheetNames[i]}</span>
    </label>`
  }
  tagstr += '</div>';
  //console.log(tagstr);
  document.getElementById("sheets").innerHTML = tagstr;
  
  //select sheet 0 in default
  selectSheet(0);
  
  //dirty ;(. Wait Dom operate completion
  for (let i=0;i<workbook.SheetNames.length;i++){
    //because chrome app don't allow inline js execution,,,
    document.getElementById(`radio-${i}`).addEventListener("click", () => {selectSheet(i)});
  }
  //
	//document.getElementById("main").addEventListener('dragenter', handleDragover, false);
	//document.getElementById("main").addEventListener('dragover', handleDragover, false);
  //document.getElementById("main").addEventListener('drop', handleDrop, false);

}

const selectSheet = arg => {
  let data = to_data(workbook,arg)
  let hot = new Handsontable(main, {
    data: data,
    minSpareRows: 1,
    rowHeaders: true,
    colHeaders: true,
    //stretchH: 'all',
    contextMenu: true
  });
}

const openSpreadsheetFile = file => {
  //show loading indicator
  document.getElementById("drop").innerHTML = `<div class="mk-spinner-wrap"><div class="mk-spinner-ring"></div></div>`;

  let reader = new FileReader();
  reader.onload = e => {
    let data = e.target.result;
    openSpreadsheetData(data);
  };
  reader.readAsBinaryString(file);
}

const openFile = () => {
  
  chrome.fileSystem.chooseEntry({
    type: 'openFile',
    accepts:[{
      extensions: ['xls','xlsx','xlsm','ods','csv']
    }]
  }, entry => {
    if (chrome.runtime.lastError) {
      showError(chrome.runtime.lastError.message);
      return;
    }
    // console.log(entry);
    entry.file(openSpreadsheetFile);
  });
}

/* set up drag-and-drop event */
const handleDrop = e => {
  //console.log("dropped");
  e.stopPropagation();
  e.preventDefault();
  // var files = e.dataTransfer.files;
  //var i,f;
  //for (i = 0, f = files[i]; i != files.length; ++i) {
  //  openSpreadsheetFile(f);
  //}
  openSpreadsheetFile(e.dataTransfer.files[0]);
}

const handleDragover = e => {
	e.stopPropagation();
	e.preventDefault();
	e.dataTransfer.dropEffect = 'copy';
}

if(main.addEventListener) {
	main.addEventListener('dragenter', handleDragover, false);
	main.addEventListener('dragover', handleDragover, false);
	main.addEventListener('drop', handleDrop, false);
}
openfile.addEventListener('click', openFile, false);

//console.log(launchData);

if (launchData && launchData.items) {
  let entry = launchData.items[0].entry;
  // console.log(entry);
  entry.file(openSpreadsheetFile);
}