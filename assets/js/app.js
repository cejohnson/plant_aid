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

// Prefetch and cache GeoJSON
// let countyGeojson
// fetch("/api/v1/geojson/counties").then((response) => {
//   if (!response.ok) {
//     throw new Error(`Error retrieving county GeoJSON: ${response.statusText}`)
//   }
//   return response.json()
// }).then((geojson) => {
//   countyGeojson = geojson
// }).catch((error) => {
//   console.error(error)
// })

let Hooks = {}

Hooks.GetCurrentPosition = {
  mounted() {
    console.log("getCurrentPosition hook mounted");
    this.el.addEventListener("click", e => {
      console.log("onclick this", this)
      console.log("onclick e", e)
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
        console.log('setting values in dom');
        console.log("sending position to server?")
        this.pushEvent("set_position", { latitude: position.coords.latitude, longitude: position.coords.longitude });
        onComplete()
      }

      let error = (error) => {
        this.pushEvent("on_get_current_position_error", { message: error.message });
        onComplete()
      }

      navigator.geolocation.getCurrentPosition(success, error, options);
    });
  }
}

Hooks.MapBox = {
  mounted() {
    console.log("mapbox container mounted")
    const map = new mapboxgl.Map({
      container: this.el,
      trackResize: false,
      style: 'mapbox://styles/mapbox/light-v10'
      // bounds: [[-125, 23], [-65, 43]]
    })

    let tempData = { type: "FeatureCollection", features: [] };

    this.handleEvent("map-data", ({ data, bounds }) => {
      console.log("setting map data", data);
      if (bounds) {
        console.log("setting bounds", bounds);
        map.fitBounds(bounds, { padding: 10 });
      }

      let source = map.getSource("counties");
      // Hacky but it works for now
      if (source) {
        source.setData(data);
      } else {
        tempData = data;
      }

      map.resize();
    })

    // this.handleEvent("map-data", (data) => {
    // let features = countyGeojson.features.filter((county) => {
    //   data[county.properties.id] != undefined;
    // }).map((county) => {
    //   county.properties.observationCount = data[county.properties.id]
    //   return county
    // })

    map.on('load', () => {
      console.log('map loaded, settings data from temp variable');
      map.addSource('counties', {
        type: "geojson",
        // data: data
        data: tempData
      });

      map.addLayer({
        'id': 'countyFill',
        'type': 'fill',
        'source': 'counties',
        'layout': {},
        'paint': {
          'fill-color': [
            'step',
            ['get', 'observation_count'],
            '#eeeeee',
            1,
            '#fcef72',
            15,
            '#e89c23',
            30,
            '#941510'
          ],
          'fill-opacity': 0.5
        }
      });

      map.addLayer({
        'id': 'countyOutline',
        'type': 'line',
        'source': 'counties',
        'layout': {},
        'paint': {
          'line-color': '#424242',
          'line-width': 0.5
        }
      });

      const hover_popup = new mapboxgl.Popup({
        closeButton: false,
        closeOnClick: false
      });

      const detail_popup = new mapboxgl.Popup({
      });

      map.on('mousemove', 'countyFill', (e) => {
        map.getCanvas().style.cursor = 'pointer';
        const props = e.features[0].properties
        if (!detail_popup.isOpen()) {

          hover_popup.setLngLat(e.lngLat)
            .setHTML(`
            <div>
            <strong>${props.name} ${props.category}, ${props.primary_subdivision}</strong>
            </div>
          ` )
            .addTo(map);
        }
      });

      map.on('mouseleave', 'countyFill', () => {
        map.getCanvas().style.cursor = '';
        hover_popup.remove();
      });

      map.on('click', 'countyFill', (e) => {
        map.getCanvas().style.cursor = 'pointer';
        const props = e.features[0].properties
        detail_popup.setLngLat(e.lngLat)
          .setHTML(`
            <h4>Detailed view</h4>
            <div>
            <strong>${props.name}</strong>
            <div>${props.observation_count} observations</div>
            <a href="#">More information</a>
            </div>
          ` )
          .addTo(map);
      });
    })
    // })
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
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  uploaders: Uploaders
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", info => topbar.delayedShow(200))
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// Populate coordinates
// window.addEventListener("plantaid:populate-coordinates", (event) => {
//   console.log("plantaid:populate-coordinates", event)
//   let button = event.target.querySelector("#get-position");
//   button.disabled = true;
//   button.textContent = "Getting Current Position...";
//   event.target.querySelector("#latitude").focus();

//   let options = {
//     enableHighAccuracy: true,
//     timeout: 15000
//   }

//   let onComplete = () => {
//     button.textContent = "Use Current Position"
//     button.disabled = false;
//   }

//   let success = (position) => {
//     console.log('sending position to server');
//     console.log(window);
//     console.log(document);
//     // event.target.querySelector("#latitude").value = position.coords.latitude;
//     // event.target.querySelector("#longitude").value = position.coords.longitude;
//     window.push("current_position", { latitude: position.coords.latitude, longitude: position.coords.longitude })
//     // event.target.querySelector("#latitude").blur();
//     onComplete()
//   }

//   let error = (error) => {
//     this.pushEvent("current_position_error", { message: error.message });
//     onComplete()
//   }

//   navigator.geolocation.getCurrentPosition(success, error, options);
// })

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

