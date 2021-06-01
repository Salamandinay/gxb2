let oBin0;
let oBin1;
let oBin2;
let oBin3;
let oBin4;
let oBin5;
let oBin6;
let oBin7;
let oBin8;
let oBin9;
let oBin10;
let oBin11;
let oBin12;
let oBin13;
let oBin14;
let oBin15;
let oBin16;
let oBin17;
let oBin18;
let oBin19;
let oBin20;
let oBin21;
let arrBins;
let arrResults;
let simNum;
let totalDrops;

let startHoursLeft;
let startMinsLeft;
let startSecsLeft;
let startDaily;
let startCurrentNum;
let startDropChance;
let startMinDrop;
let startMaxDrop;

let simRunning = false;
const totalSims = 100000;

const lsPrefix = 'cd_';


function init() {
	// check local storage
	if (typeof (Storage) !== 'undefined') {
		//if (localStorage.getItem(lsPrefix + 'daily') !== null) {
		//	document.getElementById('daily').value = localStorage.getItem(lsPrefix + 'daily');
		//	document.getElementById('currentNum').value = localStorage.getItem(lsPrefix + 'currentNum');
		//	document.getElementById('dropChance').value = localStorage.getItem(lsPrefix + 'dropChance');
		//	document.getElementById('minDrop').value = localStorage.getItem(lsPrefix + 'minDrop');
		//	document.getElementById('maxDrop').value = localStorage.getItem(lsPrefix + 'maxDrop');
		//} else {
			localStorage.setItem(lsPrefix + 'daily', 100);
			localStorage.setItem(lsPrefix + 'currentNum', 0);
			localStorage.setItem(lsPrefix + 'dropChance', 0.0926);
			localStorage.setItem(lsPrefix + 'minDrop', 8);
			localStorage.setItem(lsPrefix + 'maxDrop', 10);
		//}
	}

	oBin0 = document.getElementById('bin0');
	oBin1 = document.getElementById('bin1');
	oBin2 = document.getElementById('bin2');
	oBin3 = document.getElementById('bin3');
	oBin4 = document.getElementById('bin4');
	oBin5 = document.getElementById('bin5');
	oBin6 = document.getElementById('bin6');
	oBin7 = document.getElementById('bin7');
	oBin8 = document.getElementById('bin8');
	oBin9 = document.getElementById('bin9');
	oBin10 = document.getElementById('bin10');
	oBin11 = document.getElementById('bin11');
	oBin12 = document.getElementById('bin12');
	oBin13 = document.getElementById('bin13');
	oBin14 = document.getElementById('bin14');
	oBin15 = document.getElementById('bin15');
	oBin16 = document.getElementById('bin16');
	oBin17 = document.getElementById('bin17');
	oBin18 = document.getElementById('bin18');
	oBin19 = document.getElementById('bin19');
	oBin20 = document.getElementById('bin20');
	oBin21 = document.getElementById('bin21');
	arrBins = [oBin0, oBin1, oBin2, oBin3, oBin4, oBin5, oBin6, oBin7, oBin8, oBin9, oBin10, oBin11, oBin12, oBin13, oBin14, oBin15, oBin16, oBin17, oBin18, oBin19, oBin20, oBin21];

	updateItems();
}


let secsPassed;

function updateTime() {
	const d = new Date();
	const dEnd = new Date(d.toUTCString());
	const numDaysAdd = 6 - ((d.getUTCDay() + 2) % 7);

	dEnd.setUTCDate(d.getUTCDate() + numDaysAdd);
	dEnd.setUTCHours(23);
	dEnd.setUTCMinutes(59);
	dEnd.setUTCSeconds(59);

	const secsDiff = Math.floor((dEnd - d) / 1000);
	const hoursLeft = Math.floor(secsDiff / 60 / 60);
	const minsLeft = Math.floor((secsDiff - (hoursLeft * 60 * 60)) / 60);
	const secsLeft = secsDiff % 60;
	
	secsPassed = 604800 - secsDiff;
	document.getElementById('hoursLeft').value = hoursLeft;
	document.getElementById('minsLeft').value = minsLeft;
	document.getElementById('secsLeft').value = secsLeft;
}

function updateItems() {
	updateTime();

	let items = (secsPassed) / 60 / 5 * parseFloat(document.getElementById('dropChance').value) * (parseFloat(document.getElementById('minDrop').value) + parseFloat(document.getElementById('maxDrop').value)) / 2;
	items += document.getElementById('daily').value * (1 + Math.floor(secsPassed/86400));
	
	document.getElementById('currentNum').value = Math.floor(items);
}

function storeLocal(i) {
	if (typeof (Storage) !== 'undefined') {
		localStorage.setItem(lsPrefix + i.id, i.value);
	}
}


function runDropSim() {
	if (!(simRunning)) {
		arrResults = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		simNum = 0;
		totalDrops = 0;
		simRunning = true;

		// get starting conditions
		startHoursLeft = parseInt(document.getElementById('hoursLeft').value);
		startMinsLeft = parseInt(document.getElementById('minsLeft').value);
		startSecsLeft = parseInt(document.getElementById('secsLeft').value);
		startDaily = parseInt(document.getElementById('daily').value);
		startCurrentNum = parseInt(document.getElementById('currentNum').value);
		startDropChance = parseFloat(document.getElementById('dropChance').value);
		startMinDrop = parseInt(document.getElementById('minDrop').value);
		startMaxDrop = parseInt(document.getElementById('maxDrop').value);

		setTimeout(nextSimBlock, 1);
	}
}

function nextSimBlock() {
	if (simNum < totalSims) {
		let binNum;
		let numDrops;
		const dropsLeft = Math.floor((startHoursLeft * 60 * 60 + startMinsLeft * 60 + startSecsLeft) / 60 / 5);
		const dailyAdd = Math.floor((startHoursLeft * 60 * 60 + startMinsLeft * 60 + startSecsLeft + 132) / 60 / 60 / 24) * startDaily;

		// simulate
		for (let i = 0; i < 100; i++) {
			// reset starting conditions
			numDrops = startCurrentNum + dailyAdd;

			// simulate
			for (let j = 0; j < dropsLeft; j++) {
				if (Math.random() < startDropChance) {
					numDrops += Math.floor(Math.random() * (startMaxDrop - startMinDrop + 1)) + startMinDrop;
				}
			}

			// update results
			totalDrops += numDrops;

			if (numDrops < 999) {
				binNum = 0;
			} else if (numDrops < 1100) {
				binNum = 1;
			} else if (numDrops < 1200) {
				binNum = 2;
			} else if (numDrops < 1300) {
				binNum = 3;
			} else if (numDrops < 1400) {
				binNum = 4;
			} else if (numDrops < 1500) {
				binNum = 5;
			} else if (numDrops < 1600) {
				binNum = 6;
			} else if (numDrops < 1700) {
				binNum = 7;
			} else if (numDrops < 1800) {
				binNum = 8;
			} else if (numDrops < 1900) {
				binNum = 9;
			} else if (numDrops < 2000) {
				binNum = 10;
			} else if (numDrops < 2100) {
				binNum = 11;
			} else if (numDrops < 2200) {
				binNum = 12;
			} else if (numDrops < 2300) {
				binNum = 13;
			} else if (numDrops < 2400) {
				binNum = 14;
			} else if (numDrops < 2500) {
				binNum = 15;
			} else if (numDrops < 2600) {
				binNum = 16;
			} else if (numDrops < 2700) {
				binNum = 17;
			} else if (numDrops < 2800) {
				binNum = 18;
			} else if (numDrops < 2900) {
				binNum = 19;
			} else if (numDrops < 3000) {
				binNum = 20;
			} else if (numDrops >= 3000) {
				binNum = 21;
			}

			arrResults[binNum]++;
			simNum++;
		}

		// update results and expected values
		let percent;
		for (let i = 0; i < arrResults.length; i++) {
			percent = 100.0 * arrResults[i] / totalSims;
			arrBins[i].innerHTML = percent.toFixed(4) + '%&nbsp;';

			if (Math.round(percent) < 1) {
				arrBins[i].style.width = '1%';
			} else {
				arrBins[i].style.width = Math.round(percent) + '%';
			}
		}

		setTimeout(nextSimBlock, 1);

	} else {
		simRunning = false;
		document.getElementById('avgDrops').innerHTML = (1.0 * totalDrops / totalSims).toFixed(4);
		
		let percentComplete = secsPassed/604800.0;
		let addDaily = document.getElementById('daily').value * (1 + Math.floor(secsPassed/86400));
	
		document.getElementById('col0').innerHTML = '(' + Math.round((999-700)*percentComplete + addDaily) + '-)';
		document.getElementById('col1').innerHTML = '(' + Math.round((1099-700)*percentComplete + addDaily) + ')';
		document.getElementById('col2').innerHTML = '(' + Math.round((1199-700)*percentComplete + addDaily) + ')';
		document.getElementById('col3').innerHTML = '(' + Math.round((1299-700)*percentComplete + addDaily) + ')';
		document.getElementById('col4').innerHTML = '(' + Math.round((1399-700)*percentComplete + addDaily) + ')';
		document.getElementById('col5').innerHTML = '(' + Math.round((1499-700)*percentComplete + addDaily) + ')';
		document.getElementById('col6').innerHTML = '(' + Math.round((1599-700)*percentComplete + addDaily) + ')';
		document.getElementById('col7').innerHTML = '(' + Math.round((1699-700)*percentComplete + addDaily) + ')';
		document.getElementById('col8').innerHTML = '(' + Math.round((1799-700)*percentComplete + addDaily) + ')';
		document.getElementById('col9').innerHTML = '(' + Math.round((1899-700)*percentComplete + addDaily) + ')';
		document.getElementById('col10').innerHTML = '(' + Math.round((1999-700)*percentComplete + addDaily) + ')';
		document.getElementById('col11').innerHTML = '(' + Math.round((2099-700)*percentComplete + addDaily) + ')';
		document.getElementById('col12').innerHTML = '(' + Math.round((2199-700)*percentComplete + addDaily) + ')';
		document.getElementById('col13').innerHTML = '(' + Math.round((2299-700)*percentComplete + addDaily) + ')';
		document.getElementById('col14').innerHTML = '(' + Math.round((2399-700)*percentComplete + addDaily) + ')';
		document.getElementById('col15').innerHTML = '(' + Math.round((2499-700)*percentComplete + addDaily) + ')';
		document.getElementById('col16').innerHTML = '(' + Math.round((2599-700)*percentComplete + addDaily) + ')';
		document.getElementById('col17').innerHTML = '(' + Math.round((2699-700)*percentComplete + addDaily) + ')';
		document.getElementById('col18').innerHTML = '(' + Math.round((2799-700)*percentComplete + addDaily) + ')';
		document.getElementById('col19').innerHTML = '(' + Math.round((2899-700)*percentComplete + addDaily) + ')';
		document.getElementById('col20').innerHTML = '(' + Math.round((2999-700)*percentComplete + addDaily) + ')';
		document.getElementById('col21').innerHTML = '(' + Math.round((3000-700)*percentComplete + addDaily) + '+)';
	}
}
