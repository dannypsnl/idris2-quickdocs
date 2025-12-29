(function () {

let data = [];
let cells = [];
let initialized = false;
let matched = [];
let selected = 0;
let matcher = 'namespace';

let pendingUpdate = null;

const IDX_NAME = 0;
const IDX_NAMESPACE = 1;
const IDX_PACKAGE = 2;
const IDX_TARGET = 3;

const IDX_NAME_LOWER = 4;
const IDX_FULLNAME_LOWER = 5;

function renderEntry (entry, idx) {
  const mkEl = (s) => document.createElement(s);
  const li = mkEl('li');
  li.className = 'indexentry';
  const a = mkEl('a');
  a.setAttribute('href', 'data/' + entry[IDX_TARGET]);
  li.appendChild(a);
  li.setAttribute('data-entryidx', idx);

  const name = mkEl('span');
  name.className = 'name';
  name.innerHTML = entry[IDX_NAME];
  a.appendChild(name);

  const pkg = mkEl('span');
  pkg.className = 'package dimmed';
  pkg.innerHTML = '[' + entry[IDX_PACKAGE] + ']';
  a.appendChild(pkg);

  a.appendChild(mkEl('br'));

  const ns = mkEl('span');
  ns.className = 'namespace dimmed';
  ns.innerHTML = entry[IDX_NAMESPACE];
  a.appendChild(ns);

  a.addEventListener('click', clickResult);

  return li;
}

function isSubsequence (s, query) {
  let pos = 0;
  let queryPos = 0;

  while (queryPos < query.length) {
    const c = query[queryPos];
    const idx = s.indexOf(c, pos);

    if (idx === -1) {
      return false;
    }
    pos = idx + 1;
    ++queryPos;
  }

  return true;
}

function matchSubsequence (item, query) {
  return isSubsequence(item[IDX_FULLNAME_LOWER], query);
}

function matchNamespace (item, query) {
  // Try to escape any characters that have special meaning in a regex
  const quoted = query.replaceAll(/[.+*\\()[\]<>$|^]/g, '\\$&');
  const reQuery = new RegExp(quoted.replaceAll('\\.', '.*\\.'));
  return reQuery.test(item[IDX_FULLNAME_LOWER]);
}

function matchSimple (item, query) {
  if (item[IDX_FULLNAME_LOWER].indexOf(query) !== -1) {
    return true;
  }
  return false;
}

const matchers = {
  simple: matchSimple,
  subsequence: matchSubsequence,
  namespace: matchNamespace,
};

function openResult (linkTarget) {
  const iframe = document.querySelector('#content iframe');
  iframe.src = linkTarget;
}

function clickResult (evt) {
  const linkTarget = evt.currentTarget.getAttribute('href');

  openResult(linkTarget);

  const entryIdx = Number(evt.currentTarget.parentElement.getAttribute('data-entryidx'));
  selected = matched.indexOf(entryIdx);

  updateSelected();

  evt.preventDefault();
  return false;
}

function searchKeyDown (evt) {
  if (evt.key === 'ArrowDown') {
    ++selected;
    updateSelected();
    evt.preventDefault();
    return false;
  }
  if (evt.key === 'ArrowUp') {
    --selected;
    updateSelected();
    evt.preventDefault();
    return false;
  }
  if (evt.key === 'Enter') {
    const chosen = matched[selected];
    const chosenCell = cells[chosen];
    chosenCell.firstElementChild.click();
    evt.preventDefault();
    return false;
  }
}

function updateCellVisibility (startIndex) {
  // Keep track of how many cells where "switched" from display "block" <->
  // "none" to limit time for frame update
  let cellsChanged = 0;
  const UPDATE_BATCH_SIZE = 500;
  let i;
  for (i = startIndex; i < cells.length; ++i) {
    const entryMatches = matched.indexOf(i) !== -1;

    if (cellsChanged < UPDATE_BATCH_SIZE) {
      const oldStatus = cells[i].style.display;
      const newStatus = entryMatches ? 'block' : 'none';
      if (oldStatus !== newStatus) {
        cells[i].style.display = newStatus;
        ++cellsChanged;
      }
    } else {
      break;
    }
  }

  if (i < cells.length) {
    pendingUpdate = window.requestAnimationFrame(() => {
      // continue update in next frame
      updateCellVisibility(i);
    });
  }
}

function updateSearchResults (evt) {
  const query = evt.target.value.toLocaleLowerCase('en-US');
  matched = [];

  console.log(`search (${cells.length} / ${data.length}): `, query);
  const startTime = Number(new Date());
  const matches = matchers[matcher];

  for (let i = 0; i < data.length; ++i) {
    const entryMatches = matches(data[i], query);
    if (entryMatches) {
      matched.push(i);
    }
  }
  const finishTime = Number(new Date());
  console.log(`search took ${finishTime - startTime} ms`);

  if (pendingUpdate !== null) {
    window.cancelAnimationFrame(pendingUpdate);
    pendingUpdate = null;
  }
  updateCellVisibility(0);

  updateSelected();
}

function updateSelected () {
  selected = Math.max(0, Math.min(selected, matched.length - 1));
  let selectedCell = undefined;
  for (let i = 0; i < cells.length; ++i) {
    if (i === matched[selected]) {
      cells[i].classList.add('result-selected');
      selectedCell = cells[i];
    } else {
      cells[i].classList.remove('result-selected');
    }
  }

  if (selectedCell === undefined || !selectedCell.offsetParent) {
    return;
  }

  const parent = selectedCell.offsetParent;
  if (parent.scrollTop > selectedCell.offsetTop) {
    selectedCell.scrollIntoView(true);
  } else if ((parent.scrollTop + parent.offsetHeight) < (selectedCell.offsetTop + selectedCell.offsetHeight)) {
    selectedCell.scrollIntoView(false);
  }
}

function init () {
  if (initialized) {
    // do not init twice
    return;
  }
  initialized = true;

  const search = document.getElementById('i2d_search_results');
  const searchBox = document.getElementById('i2d_searchbox')

  fetch('data/index.json').then((res) => {
    if (res.ok) {
      return res.json();
    } else {
      throw new Error('error loading index: ' + res.status);
    }
  }).then((index) => {
    data = index;
    cells = [];
    matched = [];
    data.forEach((entry) => {
      entry[IDX_NAME_LOWER] = entry[IDX_NAME].toLocaleLowerCase('en-US');
      entry[IDX_FULLNAME_LOWER] = entry[IDX_NAMESPACE].toLocaleLowerCase('en-US') + '.' + entry[IDX_NAME].toLocaleLowerCase('en-US');

      const idx = cells.length;

      const newNode = renderEntry(entry, idx);
      search.appendChild(newNode);
      cells.push(newNode);
      matched.push(idx);
    });

    updateSelected();
    searchBox.focus();
  });

  searchBox.addEventListener('input', (evt) => {
    updateSearchResults(evt);
  });

  searchBox.addEventListener('keydown', searchKeyDown);

  document.addEventListener('keydown', (evt) => {
    if (evt.key === 'Tab' && document.activeElement !== searchBox) {
      searchBox.focus();
      searchBox.select();
      evt.preventDefault();
      return false;
    }
  });

  const iframe = document.querySelector('#content iframe');
  iframe.addEventListener('load', (evt) => {
    console.log('iframe loaded', evt);
    document.title = iframe.contentWindow.document.title;

    iframe.contentWindow.document.addEventListener('keydown', (evt) => {
      if (evt.key === 'Tab') {
        searchBox.focus();
        searchBox.select();
        evt.preventDefault();
        return false;
      }
    });
  });
}

document.addEventListener('DOMContentLoaded', init, { once: true });
if (document.readyState === 'interactive') {
  init();
}

})();
