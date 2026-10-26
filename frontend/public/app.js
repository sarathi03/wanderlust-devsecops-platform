// All API calls use RELATIVE paths (/api/...). nginx forwards them to the
// backend Service inside the cluster, so no server IP is baked into the image.

async function getJson(path) {
  const res = await fetch(path, { cache: 'no-store' });
  if (!res.ok) throw new Error(`${path} returned ${res.status}`);
  return res.json();
}

function show(id, text) {
  document.getElementById(id).textContent = text;
}

getJson('/version.json')
  .then((data) => show('frontend-version', data.version))
  .catch(() => show('frontend-version', 'unknown'));

getJson('/api/info')
  .then((info) => {
    show('backend-version', info.version);
    show('backend-pod', info.hostname);
  })
  .catch(() => {
    show('backend-version', 'backend unreachable');
    show('backend-pod', '-');
  });

getJson('/api/destinations')
  .then((items) => {
    const list = document.getElementById('destinations');
    list.innerHTML = '';
    for (const item of items) {
      const li = document.createElement('li');
      li.textContent = `${item.name}, ${item.country} - ${item.tip}`;
      list.appendChild(li);
    }
  })
  .catch(() => show('destinations', 'Could not load destinations'));
