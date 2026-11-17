const RES = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'rose_Movie-Mode';

const panel  = document.getElementById('panel');
const toggle = document.getElementById('toggle');
const pill   = document.getElementById('pill');
const tTitle = document.getElementById('tTitle');
const tSub   = document.getElementById('tSub');

let isOpen = false;

function post(name, data = {}) {
    return fetch(`https://${RES}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

const optNoclip = document.getElementById('optNoclip');
const optInvis  = document.getElementById('optInvis');
const sNoclip   = document.getElementById('sNoclip');
const sInvis    = document.getElementById('sInvis');

function render(s) {
    s = s || {};
    const film = !!s.film, noclip = !!s.noclip, invis = !!s.invisible;

    panel.classList.toggle('on', film);
    pill.textContent   = film ? 'REC' : 'AUS';
    tTitle.textContent = film ? 'Filmmodus beenden' : 'Filmmodus starten';
    tSub.textContent   = film ? 'Noclip und Unsichtbarkeit verfuegbar' : 'Schaltet Noclip und Unsichtbarkeit frei';
    toggle.disabled = false;

    optNoclip.classList.toggle('active', noclip);
    optNoclip.disabled = !film;
    sNoclip.textContent = !film ? 'Erst Filmmodus starten' : (noclip ? 'Aktiv - du bist unsichtbar' : 'Fliegen, immer unsichtbar');

    optInvis.classList.toggle('active', invis);
    optInvis.classList.toggle('locked', noclip);
    optInvis.disabled = !film || noclip;
    sInvis.textContent = !film ? 'Erst Filmmodus starten' : (noclip ? 'Durch Noclip aktiv' : (invis ? 'Aktiv' : 'Ohne Noclip unsichtbar laufen'));
}

function open(s) {
    isOpen = true;
    panel.classList.remove('hidden', 'closing');
    render(s);
}

function close(notify = true) {
    if (!isOpen) return;
    isOpen = false;
    panel.classList.add('closing');
    setTimeout(() => { if (!isOpen) panel.classList.add('hidden'); }, 200);
    if (notify) post('close');
}

[toggle, optNoclip, optInvis].forEach((btn) => {
    btn.addEventListener('click', () => {
        if (btn.disabled) return;
        btn.disabled = true;
        post('toggle', { what: btn.dataset.what });
    });
});

window.addEventListener('message', (e) => {
    const d = e.data || {};
    if (d.action === 'open')  open(d.state);
    if (d.action === 'state') render(d.state);
    if (d.action === 'close') close(false);
});

// Dem Client melden, dass die Seite geladen ist (wiederholen, bis der Lua-Callback antwortet)
(function sayReady(tries) {
    fetch(`https://${RES}/ready`, { method: 'POST', body: '{}' })
        .then(r => { if (!r.ok) throw 0; })
        .catch(() => { if (tries > 0) setTimeout(() => sayReady(tries - 1), 1000); });
})(15);

window.addEventListener('keydown', (e) => {
    if (isOpen && (e.key === 'Escape' || e.key === 'Backspace')) close();
});
