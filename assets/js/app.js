// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

mapboxgl.accessToken = "pk.eyJ1Ijoic2hhbmtqNjg3IiwiYSI6ImNsNHlneGluejFqaDkzam5rNmc1Nmg1c2oifQ.OKCoEsxl4NF19EnW95zc7A"

let Hooks = {}

Hooks.GetCurrentPosition = {
  mounted() {
    this.el.addEventListener("click", e => {
      e.target.textContent = "Retrieving Position...";
      e.target.disabled = true;

      let options = {
        enableHighAccuracy: true,
        timeout: 15000
      }

      let onComplete = () => {
        e.target.textContent = "Use Current Position"
        e.target.disabled = false;
      }

      let success = (position) => {
        pushEvent("current_position", { latitude: position.coords.latitude, longitude: position.coords.longitude });
        onComplete()
      }

      let error = (error) => {
        pushEvent("on_get_current_position_error", { message: error.message });
        onComplete()
      }

      let pushEvent = (event, payload) => {
        let target = this.el.getAttribute("phx-target");
        if (target) {
          this.pushEventTo(target, event, payload)
        } else {
          this.pushEvent(event, payload)
        }
      }

      navigator.geolocation.getCurrentPosition(success, error, options);
    });
  }
}

Hooks.MapBoxAggregateData = {
  mounted() {
    const map = new mapboxgl.Map({
      container: this.el,
      trackResize: false,
      style: 'mapbox://styles/mapbox/light-v10'
    })

    let tempData = { type: "FeatureCollection", features: [] };

    window.addEventListener("resize", (event) => {
      map.resize();
    });

    this.handleEvent("map-data", ({ data, bounds }) => {
      if (bounds) {
        map.fitBounds(bounds, { padding: 10 });
      }

      let source = map.getSource("regions");
      // Hacky but it works for now
      if (source) {
        source.setData(data);
      } else {
        tempData = data;
      }

      map.resize();
    })

    map.on('load', () => {
      map.addSource('regions', {
        type: "geojson",
        data: tempData
      });

      map.addLayer({
        'id': 'regionFill',
        'type': 'fill',
        'source': 'regions',
        'layout': {},
        'paint': {
          'fill-color': [
            'step',
            ['get', 'observation_count'],
            '#eeeeee',
            1,
            '#f5f087',
            5,
            '#e3c749',
            10,
            '#c78a28',
            20,
            "#b54f14",
            30,
            "#8a0000",
          ],
          'fill-opacity': 0.5
        }
      });

      map.addLayer({
        'id': 'regionOutline',
        'type': 'line',
        'source': 'regions',
        'layout': {},
        'paint': {
          'line-color': '#8D8D8D',
          'line-width': 0.5
        }
      });

      const hover_popup = new mapboxgl.Popup({
        closeButton: false,
        closeOnClick: false
      });

      const detail_popup = new mapboxgl.Popup({
      });

      const as_percent = (numerator, denominator) => {
        return Number(numerator / denominator).toLocaleString(undefined, { style: 'percent', minimumFractionDigits: 1 })
      }

      map.on('mousemove', 'regionFill', (e) => {
        map.getCanvas().style.cursor = 'pointer';
        const props = e.features[0].properties
        if (!detail_popup.isOpen()) {
          const counts = JSON.parse(props.counts)
          console.log(props)

          hover_popup.setLngLat(e.lngLat)
            .setHTML(`
              <div>
              <strong>${props.name} ${props.category}, ${props.primary_subdivision}, ${props.country}</strong>
              <div>Total Observations: ${props.observation_count}</div>
              <div>Confirmed Disease</div>
              <ul class="list-disc list-inside pl-2">${counts.map(pathology => {
              if (pathology.name === "Unknown") {
                return `
                  <li>
                  ${pathology.name}: ${as_percent(pathology.count, props.observation_count)} (${pathology.count})
                  </li>
                  `
              } else {
                return `
                  <li>
                  ${pathology.name}: ${as_percent(pathology.count, props.observation_count)} (${pathology.count})
                  <div class="pl-3">
                  <ul class="list-disc list-inside pl-2">
                    ${pathology.genotypes.map(genotype => {
                  return `
                        <li>
                          ${genotype.name}: ${as_percent(genotype.count, pathology.count)} (${genotype.count})
                        </li>
                      `
                }).join("\n")}
                  </ul>
                  </div>
                  </li>
                `}
            }).join("\n")}</ul>
            </div>
            ` )
            .addTo(map);

        }
      });

      map.on('mouseleave', 'regionFill', () => {
        map.getCanvas().style.cursor = '';
        hover_popup.remove();
      });

      map.on('click', 'regionFill', (e) => {
        map.getCanvas().style.cursor = 'pointer';
        const props = e.features[0].properties
        const counts = JSON.parse(props.counts)
        detail_popup.setLngLat(e.lngLat)
          .setHTML(`
          <div>
              <strong>${props.name} ${props.category}, ${props.primary_subdivision}, ${props.country}</strong>
              <div>Total Observations: ${props.observation_count}</div>
              <div>Confirmed Disease</div>
              <ul class="list-disc list-inside pl-2">${counts.map(pathology => {
            if (pathology.name === "Unknown") {
              return `
                  <li>
                  ${pathology.name}: ${Number(pathology.genotypes[0].count / props.observation_count).toLocaleString(undefined, { style: 'percent', minimumFractionDigits: 1 })}
                  </li>
                  `
            } else {
              return `
                  <li>
                  <div>${pathology.name}</div>
                  <div class="pl-3">
                  <div>Genotypes</div>
                  <ul class="list-disc list-inside pl-2">
                    ${pathology.genotypes.map(genotype => {
                return `
                        <li>
                          ${genotype.name}: ${Number(genotype.count / props.observation_count).toLocaleString(undefined, { style: 'percent', minimumFractionDigits: 1 })}
                        </li>
                      `
              }).join("\n")}
                  </ul>
                  </div>
                  </li>
                `}
          }).join("\n")}</ul>
            </div>
          ` )
          .addTo(map);
      });
    })
  }
}

Hooks.MapBoxPointData = {
  mounted() {
    console.log("mapbox container mounted")
    const map = new mapboxgl.Map({
      container: this.el,
      trackResize: false,
      style: 'mapbox://styles/mapbox/light-v10'
    })

    let tempData = { type: "FeatureCollection", features: [] };

    window.addEventListener("resize", (event) => {
      map.resize();
    });

    this.handleEvent("map-data", ({ data, bounds }) => {
      console.log("setting map data", data);
      if (bounds) {
        console.log("setting bounds", bounds);
        map.fitBounds(bounds, { padding: 10 });
      }

      let source = map.getSource("observations");
      // Hacky but it works for now
      if (source) {
        source.setData(data);
      } else {
        tempData = data;
      }

      map.resize();
    })

    map.on('load', () => {
      console.log('map loaded, settings data from temp variable');
      map.addSource('observations', {
        type: "geojson",
        // cluster: true,
        // clusterMaxZoom: 16,
        // clusterRadius: 50,
        data: tempData
      });

      map.addLayer({
        'id': 'clusters',
        'type': 'circle',
        'source': 'observations',
        filter: ['has', 'point_count'],
        paint: {
          // Use step expressions (https://docs.mapbox.com/mapbox-gl-js/style-spec/#expressions-step)
          // with three steps to implement three types of circles:
          //   * Blue, 20px circles when point count is less than 100
          //   * Yellow, 30px circles when point count is between 100 and 750
          //   * Pink, 40px circles when point count is greater than or equal to 750
          'circle-color': [
            'step',
            ['get', 'point_count'],
            '#51bbd6',
            100,
            '#f1f075',
            750,
            '#f28cb1'
          ],
          'circle-radius': [
            'step',
            ['get', 'point_count'],
            20,
            100,
            30,
            750,
            40
          ]
        }
      });

      map.addLayer({
        id: 'cluster-count',
        type: 'symbol',
        source: 'observations',
        filter: ['has', 'point_count'],
        layout: {
          'text-field': '{point_count_abbreviated}',
          'text-font': ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          'text-size': 12
        }
      });

      map.addLayer({
        id: 'unclustered-point',
        type: 'circle',
        source: 'observations',
        filter: ['!', ['has', 'point_count']],
        paint: {
          'circle-color': [
            'match',
            ['get', 'p'],
            'Late Blight',
            '#FA7633',
            'Cucurbit Downy Mildew',
            '#8E55D5',
            // 'Cucumber',
            // '#73af59',
        /* other */ '#cccc00'
          ],
          'circle-radius': 6,
          'circle-stroke-width': 1,
          'circle-stroke-color': '#fff'
        }
      });

      const hover_popup = new mapboxgl.Popup({
        closeButton: false,
        closeOnClick: false
      });

      const detail_popup = new mapboxgl.Popup({
      });

      map.on('mousemove', 'unclustered-point', (e) => {
        map.getCanvas().style.cursor = 'pointer';
        const props = e.features[0].properties
        if (!detail_popup.isOpen()) {

          hover_popup.setLngLat(e.lngLat)
            .setHTML(`
            <div>
            <strong>${props.p}</strong>
            <div>Host: ${props.h} </div>
            <div>Date: ${props.d} </div>
            <div>Location: ${props.l} </div>
            </div>
          ` )
            .addTo(map);
        }
      });

      map.on('mouseleave', 'unclustered-point', () => {
        map.getCanvas().style.cursor = '';
        hover_popup.remove();
      });

      map.on('click', 'unclustered-point', (e) => {
        map.getCanvas().style.cursor = 'pointer';
        const props = e.features[0].properties;
        window.location.href = `/observations/${props.id}`;
      });
    })
  }
}

let Uploaders = {}

Uploaders.S3 = function (entries, onViewError) {
  entries.forEach(entry => {
    let formData = new FormData()
    let { url, fields } = entry.meta
    Object.entries(fields).forEach(([key, val]) => formData.append(key, val))
    formData.append("file", entry.file)
    let xhr = new XMLHttpRequest()
    onViewError(() => xhr.abort())
    xhr.onload = () => xhr.status === 204 ? entry.progress(100) : entry.error()
    xhr.onerror = () => entry.error()
    xhr.upload.addEventListener("progress", (event) => {
      if (event.lengthComputable) {
        let percent = Math.round((event.loaded / event.total) * 100)
        if (percent < 100) { entry.progress(percent) }
      }
    })

    xhr.open("POST", url, true)
    xhr.send(formData)
  })
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken, user_token: window.userToken },
  hooks: Hooks,
  uploaders: Uploaders
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", info => topbar.delayedShow(200))
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

if (window.userToken) {
  let socket = new Socket("/socket", { params: { user_token: window.userToken } })
  socket.connect()
  let channel = socket.channel("presence", {})
  channel.join()
  // .receive("ok", resp => { console.log("Socket connected", resp) })
  //   .receive("error", resp => { console.log("Socket error", resp) })
}


// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

