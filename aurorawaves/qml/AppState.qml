import QtQuick
import QtQuick.Layouts
import "kshim"
import "presets.js" as Presets
import "i18n.js" as I18n

// The app's state and actions (ported from the widget's main.qml): stations, playback through the
// in-app player, YouTube Music queue, cover art for MPRIS. Every page talks to it as `app`.
Item {
    id: root

    readonly property QtObject cfg: Prefs
    property bool expanded: true           // the window is shown

    // ---------- language ----------
    readonly property string lang: I18n.resolve(cfg.language, Qt.locale().name)
    readonly property bool rtl: lang === "ar"
    function t(s) { return I18n.tr(lang, s) }
    // ISO country of the desktop locale ("ar_EG" -> "EG"); drives defaults and Discover
    readonly property string systemCountry: {
        var p = Qt.locale().name.split("_")
        return p.length > 1 && /^[A-Za-z]{2}$/.test(p[1]) ? p[1].toUpperCase() : ""
    }

    // ---------- data ----------
    property var stations: []
    property string currentId: cfg.lastStation
    readonly property var current: findStation(currentId, stations)
    readonly property color accent: (cfg.useStationAccent && current) ? current.color : Theme.highlightColor
    readonly property var groups: {
        var g = []
        for (var i = 0; i < stations.length; i++) {
            var name = stations[i].group || ""
            if (name !== "" && g.indexOf(name) < 0) g.push(name)
        }
        return g
    }
    property string groupFilter: ""

    // ---------- playback state (mirrors radiod) ----------
    property string playState: "stopped"   // stopped | connecting | playing | paused | error
    property bool daemonAlive: false
    property string trackTitle: ""
    property string trackArtist: ""
    property string streamInfo: ""
    property real position: 0
    property real duration: 0
    property bool localPlayback: false
    property int track: 0
    property int tracks: 0
    property int volume: cfg.volume
    property double volumeTouched: 0
    property bool ytQueueFetching: false
    property bool editing: false

    // ---------- YouTube Music (optional; see code/ytmusic.py) ----------
    property bool ytMode: false            // the daemon is on a YouTube Music queue
    property var ytQueue: []               // [{id,title,artist,album,duration,thumb}]
    property int ytIndex: 0                // song of ytQueue being played
    property string ytName: ""             // what the queue came from ("Warda", an album...)
    property string ytArt: ""
    property var ytStatus: ({ checked: false, ready: false })
    property bool ytSetupBusy: false
    readonly property var ytTrack: ytMode && ytIndex >= 0 && ytIndex < ytQueue.length ? ytQueue[ytIndex] : null

    readonly property bool wantPlaying: playState === "connecting" || playState === "playing" || playState === "paused"
    readonly property bool isPlaying: playState === "playing"
    readonly property bool isBusy: playState === "connecting"
    readonly property bool isPaused: playState === "paused"


    // ---------- helpers ----------
    function findStation(id, list) {
        if (!list || list.length === 0) return null
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return list[i]
        return list[0]
    }

    function indexOfStation(id) {
        for (var i = 0; i < stations.length; i++)
            if (stations[i].id === id) return i
        return -1
    }

    // image url for a logo string (no icon/glyph); used by the ambient backdrop
    function logoUrl(logo) {
        if (!logo || logo.indexOf("icon:") === 0) return ""
        if (logo.indexOf("pkg:") === 0) return Qt.resolvedUrl("../assets/logos/" + logo.slice(4))
        return logo
    }

    function kindOf(st) {
        if (!st) return "stream"
        if (st.kind) return st.kind
        var u = (st.url || "").toLowerCase()
        if (u.indexOf("file://") !== 0 && u.indexOf("/") !== 0) return "stream"
        if (/\.(m3u8?|pls)$/.test(u)) return "playlist"
        return "file"
    }

    function fmtTime(s) {
        s = Math.max(0, Math.floor(s))
        var m = Math.floor(s / 60), h = Math.floor(m / 60)
        var ss = (s % 60 < 10 ? "0" : "") + (s % 60)
        return h > 0 ? h + ":" + ((m % 60) < 10 ? "0" : "") + (m % 60) + ":" + ss : m + ":" + ss
    }

    function statusText() {
        switch (playState) {
        case "connecting": return t("جاري الاتصال…")
        case "playing":
            if (ytMode) return t("يوتيوب ميوزك") + (ytQueue.length > 1 ? "  ·  " + (ytIndex + 1) + " / " + ytQueue.length : "")
            if (trackTitle !== "") return trackTitle
            return localPlayback ? t("تشغيل من ملفاتك") : t("على الهواء مباشرة")
        case "paused":     return t("متوقف مؤقتًا")
        case "error":      return t("تعذّر التشغيل — اضغط للمحاولة مرة أخرى")
        default:           return t("متوقف")
        }
    }

    function loadStations() {
        var raw = Backend.readConfig("stations.json")
        var list = null
        if (raw && raw.length > 0) {
            try { list = JSON.parse(raw) } catch (e) { list = null }
        }
        if (!Array.isArray(list)) {
            list = Presets.defaults(lang, systemCountry)
            Backend.writeConfig("stations.json", JSON.stringify(list, null, 1))
        }
        stations = list
    }

    function saveStations(list) {
        stations = list.slice()
        Backend.writeConfig("stations.json", JSON.stringify(stations, null, 1))
        if (indexOfStation(currentId) < 0 && stations.length > 0)
            currentId = stations[0].id
        if (groupFilter !== "" && groups.indexOf(groupFilter) < 0) groupFilter = ""
        artStage.renderAll()
    }

    // what the daemon needs to know about each station
    function daemonStations() {
        var out = []
        for (var i = 0; i < stations.length; i++) {
            var s = stations[i]
            out.push({ id: s.id, name: s.name, subtitle: s.subtitle || "", url: s.url,
                       kind: kindOf(s), shuffle: !!s.shuffle, art: artStage.artFor(s) })
        }
        return out
    }

    // ---------- bridge to the Python side ----------
    function shq(s) { return String(s) }
    function parseReply(out) { try { return JSON.parse(out) } catch (e) { return { error: "bad reply" } } }

    // directory / logo / check helpers; cb receives parsed JSON (or {error})
    function runSources(cmd, arg, cb) {
        Backend.run("sources", cmd, typeof arg === "string" ? arg : JSON.stringify(arg),
                    function (out) { if (cb) cb(root.parseReply(out)) })
    }
    function runYt(cmd, arg, cb) {
        Backend.run("yt", cmd, typeof arg === "string" ? arg : JSON.stringify(arg),
                    function (out) { if (cb) cb(root.parseReply(out)) })
    }
    function ytTakeStatus(r) {
        if (!r || r.ready === undefined) return
        ytStatus = { checked: true, ready: r.ready, ytdlp: r.ytdlp, days: r.updatedDays,
                     signedIn: !!r.signedIn, account: r.account || {}, browsers: r.browsers || [],
                     managed: !!r.managed, helperCmd: r.helperCmd || "" }
    }
    function ytCheck(cb) {
        runYt("status", "-", function (r) {
            ytTakeStatus(r)
            if (r && r.ready && (r.updatedDays < 0 || r.updatedDays > 5)) runYt("update", "-", ytTakeStatus)
            if (cb) cb(ytStatus)
        })
    }
    function ytSetup(cb) {
        ytSetupBusy = true
        runYt("setup", "-", function (r) {
            ytSetupBusy = false
            ytTakeStatus(r)
            if (cb) cb(r)
        })
    }
    // optional Google account: {browser: "chrome"} or {headers: "..."}
    function ytLogin(params, cb) {
        runYt("login", JSON.stringify(params), function (r) {
            ytCheck(function () { if (cb) cb(r) })
        })
    }
    function ytLogout(cb) {
        runYt("logout", "-", function (r) { ytCheck(function () { if (cb) cb(r) }) })
    }

    // play a list of songs, starting at one of them
    function playYt(list, start, name) {
        if (!list || list.length === 0) return
        // keep the request small (it travels as one command-line argument)
        if (list.length > 200) {
            var from = Math.max(0, Math.min((start || 0) - 20, list.length - 200))
            list = list.slice(from, from + 200)
            start = (start || 0) - from
        }
        start = Math.max(0, Math.min(list.length - 1, start || 0))
        ytQueue = list.slice()
        ytIndex = start
        ytName = name || ""
        ytMode = true
        ytArt = list[start].thumb || ""
        daemonCurrentId = "yt"
        playState = "connecting"
        trackTitle = list[start].title
        trackArtist = list[start].artist
        position = 0
        duration = list[start].duration || 0
        var st = daemonStations()
        st.push({ id: "yt", name: ytName || t("يوتيوب ميوزك"), subtitle: "", url: "", kind: "yt",
                  queue: ytQueue, start: start, art: ytArt })
        send({ cmd: "play", id: "yt", stations: st, volume: volume })
    }
    // add songs to the playing queue (next, or at the end); starts playing if nothing is
    function enqueueYt(list, next) {
        if (!ytMode || !wantPlaying) { playYt(list, 0, ""); return }
        if (ytQueue.length + list.length > 300) list = list.slice(0, Math.max(0, 300 - ytQueue.length))
        if (list.length === 0) return
        var q = ytQueue.slice()
        var at = next ? ytIndex + 1 : q.length
        Array.prototype.splice.apply(q, [at, 0].concat(list))
        ytQueue = q
        send({ cmd: "enqueue", tracks: list, next: !!next })
    }
    function jumpYt(i) {
        if (!ytMode) return
        if (!wantPlaying) { playYt(ytQueue, i, ytName); return }
        ytIndex = i
        send({ cmd: "jump", index: i })
    }
    function seek(sec) {
        position = sec
        send({ cmd: "seek", pos: sec })
    }

    function exec(script, args, cb) {
        var cmd = "python3 -I " + shq(script) + " " + args
        if (cb) callbacks[cmd] = cb
        executable.connectSource(cmd)
    }
    function run(args, cb) { exec(scriptPath, args, cb) }

    // listen to something that is not (yet) a saved station
    property string previewName: ""
    property string previewLogo: ""
    property string daemonCurrentId: ""
    readonly property bool previewing: daemonCurrentId === "preview" && wantPlaying

    property string previewColor: Presets.palette[0]

    function colorForName(name) {
        var h = 0
        for (var i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0
        return Presets.palette[h % Presets.palette.length]
    }

    function preview(name, url, kind, shuffle, logo) {
        name = name || t("تجربة")
        logo = logo || ""
        var list = daemonStations()
        // a plain image logo can be used as cover right away; the glass render replaces it
        var quickArt = /^(https?|file):\/\//.test(logo) ? logo : ""
        list.push({ id: "preview", name: name, url: url, kind: kind || "stream",
                    shuffle: !!shuffle, art: quickArt })
        previewName = name
        previewLogo = logo
        previewColor = colorForName(name)
        daemonCurrentId = "preview"
        playState = "connecting"
        send({ cmd: "play", id: "preview", stations: list, volume: volume })
        artStage.renderOne({ id: "preview", logo: logo, color: previewColor, glyph: Presets.glyphFor(name) },
                           function (art) { root.send({ cmd: "art", id: "preview", art: art }) })
    }

    function send(req) {
        req.mpris = cfg.mprisEnabled
        req.appName = t("أمواج أورورا")
        req.liveText = t("بث مباشر")
        handleStatus(parseReply(Backend.send(JSON.stringify(req))))
    }

    // ---------- actions ----------
    function play(id) {
        if (id !== undefined && id !== null) {
            currentId = id
            cfg.lastStation = id
        }
        if (!current) return
        // a saved YouTube Music station ("artist:ID", "album:ID", "radio:VIDEO"): fetch its songs
        // for proper titles and covers; its playlist url is the fallback (media keys, errors)
        if (current.kind === "yt" && current.ytRef) {
            var st = current
            playState = "connecting"
            var ref = st.ytRef.split(":")
            runYt(ref[0], ref.slice(1).join(":"), function (r) {
                var list = r && (r.songs || r.tracks)
                if (list && list.length) {
                    if (st.shuffle) list = shuffled(list)
                    playYt(list, 0, st.name)
                } else {
                    ytMode = false
                    daemonCurrentId = st.id
                    send({ cmd: "play", id: st.id, stations: daemonStations(), volume: volume })
                }
            })
            return
        }
        ytMode = false
        playState = "connecting"
        daemonCurrentId = current.id
        trackTitle = ""
        streamInfo = ""
        send({ cmd: "play", id: current.id, stations: daemonStations(), volume: volume })
    }

    function shuffled(list) {
        var a = list.slice()
        for (var i = a.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1)); var tmp = a[i]; a[i] = a[j]; a[j] = tmp
        }
        return a
    }

    function stop() {
        playState = "stopped"
        trackTitle = ""
        streamInfo = ""
        send({ cmd: "stop" })
    }

    function toggle() {
        if (!daemonAlive || playState === "stopped" || playState === "error") {
            if (ytMode && ytQueue.length > 0) playYt(ytQueue, ytIndex, ytName)
            else play(null)
            return
        }
        send({ cmd: "toggle", stations: daemonStations(), volume: volume })
    }

    function step(delta) {
        if (ytMode && wantPlaying) {
            send({ cmd: delta > 0 ? "next" : "prev" })
            return
        }
        if (stations.length === 0) return
        var i = indexOfStation(current ? current.id : "")
        play(stations[(i + delta + stations.length) % stations.length].id)
    }

    function setVolume(v) {
        v = Math.max(0, Math.min(100, Math.round(v)))
        if (v === volume) return
        volume = v
        volumeTouched = Date.now()
        volumeCommit.restart()
    }

    Timer {
        id: volumeCommit
        interval: 150
        onTriggered: {
            root.cfg.volume = root.volume
            if (root.daemonAlive) root.send({ cmd: "volume", v: root.volume })
        }
    }

    function handleStatus(s) {
        daemonAlive = !!s.daemon
        if (!s.daemon) {
            if (playState !== "error") playState = "stopped"
            return
        }
        if (s.error) return
        playState = s.state
        daemonCurrentId = s.currentId || ""
        if (s.currentId && s.currentId !== currentId && indexOfStation(s.currentId) >= 0) {
            currentId = s.currentId          // e.g. changed by media keys / visualizer
            cfg.lastStation = s.currentId
        }
        trackTitle = s.title || ""
        trackArtist = s.artist || ""
        localPlayback = !!s.local
        if (s.yt) {
            ytMode = true
            ytIndex = (s.track || 1) - 1
            if (s.art) ytArt = s.art
            // e.g. after a plasmashell restart, or songs added from the media controller
            if (s.ytId && (s.tracks || 0) !== ytQueue.length && !ytQueueFetching) {
                ytQueueFetching = true
                send({ cmd: "queue" })
            }
            if (s.queue) { ytQueue = s.queue; ytQueueFetching = false }
        } else if (s.currentId && s.currentId !== "yt" && s.state !== "stopped") {
            ytMode = false
        }
        position = s.pos || 0
        duration = s.duration || 0
        track = s.track || 0
        tracks = s.tracks || 0
        streamInfo = (s.codec ? s.codec.toUpperCase() : "")
                   + (s.bitrate ? " · " + Math.round(s.bitrate / 1000) + " kbps" : "")
        if (Date.now() - volumeTouched > 2000 && s.volume !== undefined && s.volume !== volume) {
            volume = s.volume
            cfg.volume = s.volume
        }
    }

    Timer {
        id: poll
        interval: (root.expanded || root.wantPlaying) ? 1000 : 4000
        repeat: true
        running: root.daemonAlive || root.expanded
        triggeredOnStart: true
        onTriggered: root.send({ cmd: "status" })
    }

    // ---------- MPRIS cover art: render each logo to a PNG ----------
    Item {
        id: artStage
        x: -4000
        width: 256
        height: 256

        property string artDir: ""
        property var done: ({})      // id -> key of the rendered file
        property var queue: []
        property var job: null

        function keyFor(s) {
            var str = (s.logo || "") + "|" + s.color + "|" + (s.glyph || "") + "|" + root.cfg.logoShape
            var h = 5381
            for (var i = 0; i < str.length; i++) h = ((h * 33) ^ str.charCodeAt(i)) >>> 0
            return h.toString(36)
        }
        function pathFor(s) { return artDir + "/" + s.id + "-" + keyFor(s) + ".png" }
        function artFor(s) {
            if (artDir !== "" && done[s.id] === keyFor(s)) return "file://" + pathFor(s)
            var u = root.logoUrl(s.logo)
            return u.toString().indexOf("file://") === 0 ? u.toString() : ""
        }
        function renderAll() {
            if (artDir === "") return
            var q = []
            for (var i = 0; i < root.stations.length; i++)
                if (done[root.stations[i].id] !== keyFor(root.stations[i])) q.push(root.stations[i])
            // keep one-off jobs (previews) that are still waiting
            queue = q.concat(queue.filter(function (j) { return !!j.cb }))
            if (!job) next()
        }
        // render a single cover now and hand its file url to cb
        function renderOne(st, cb) {
            if (artDir === "") return
            var j = JSON.parse(JSON.stringify(st))
            j.cb = cb
            queue = queue.filter(function (q) { return q.id !== j.id }).concat([j])
            if (!job) next()
        }
        property bool stationJobs: false
        function next() {
            if (queue.length === 0) {
                job = null
                if (stationJobs && root.daemonAlive) root.send({ cmd: "sync", stations: root.daemonStations() })
                stationJobs = false
                return
            }
            job = queue[0]
            queue = queue.slice(1)
            if (!job.cb) stationJobs = true
            artLogo.logo = job.logo || ""
            artLogo.tint = job.color
            artLogo.glyph = job.glyph || ""
            grabDelay.waited = 0
            grabDelay.restart()
        }

        StationLogo { id: artLogo; anchors.fill: parent }

        Timer {
            id: grabDelay
            interval: 250
            property int waited: 0
            onTriggered: {
                // give remote logos (favicons) up to ~4s to arrive before capturing
                if (artLogo.imageUrl !== "" && !artLogo.hasImage && waited < 4000) {
                    waited += interval
                    restart()
                    return
                }
                var s = artStage.job
                var ok = artLogo.grabToImage(function (result) {
                    var path = artStage.pathFor(s)
                    if (result.saveToFile(path)) {
                        if (s.cb) s.cb("file://" + path)
                        else {
                            var d = artStage.done
                            d[s.id] = artStage.keyFor(s)
                            artStage.done = d
                        }
                    }
                    artStage.next()
                }, Qt.size(256, 256))
                if (!ok) artStage.next()
            }
        }
    }

    Connections {
        target: root.cfg
        function onLogoShapeChanged() { artStage.renderAll() }
        function onMprisEnabledChanged() { if (root.daemonAlive) root.send({ cmd: "sync" }) }
    }

    Component.onCompleted: {
        loadStations()
        if (indexOfStation(currentId) < 0 && stations.length > 0)
            currentId = stations[0].id
        artStage.artDir = Backend.artDir
        artStage.renderAll()
        // the player lives in this process: start from its state, resume if asked
        root.send({ cmd: "volume", v: root.volume })
        if (root.cfg.resumeOnStart && root.playState === "stopped") root.play(null)
    }
}
