import { useState, useRef, useEffect } from 'react';
import {
  StyleSheet, View, Text, TouchableOpacity,
  SafeAreaView, StatusBar, Animated, Dimensions,
  Image, useColorScheme, Modal, Linking, Easing,
  PanResponder, Platform,
} from 'react-native';
import { WebView } from 'react-native-webview';
import Svg, { Path, Circle } from 'react-native-svg';

const LOGIN_URL  = 'https://myaccount.assurancewireless.com/login/start';
const SIGNUP_URL = 'https://www.assurancewireless.com/';
const BASE       = 'https://myaccount.assurancewireless.com';
const { width, height } = Dimensions.get('window');
const CYAN   = '#00aeef';
const PURPLE = '#6d2077';
const LOGO_HEADER = 'https://freeimage.host/images/2024/BrzIqiB.png';
const LOGO_SPLASH = require('./assets/Assurance_Wireless_logo.png');

const TABS = [
  { label: 'Home',    url: `${BASE}/my-account/dashboard`,       match: 'dashboard' },
  { label: 'Usage',   url: `${BASE}/my-account/usage-history`,   match: 'usage' },
  { label: 'Add-Ons', url: `${BASE}/my-account/select-services`, match: 'select-services' },
  { label: 'Alerts',  url: `${BASE}/my-account/notifications`,   match: 'notification' },
  { label: 'Profile', url: `${BASE}/my-account/profile`,         match: 'profile' },
];

const INJECTED_CSS = `(function(){
  var s=document.createElement('style');
  s.innerHTML='.site-header,.app-header,.main-header,[class*="TopNav"],[class*="top-nav"],[class*="SiteNav"],[class*="site-nav"],[id="header"],[id="site-header"],.footer-wrapper,.site-footer,.main-footer,[id="footer"]{display:none!important}body{padding-bottom:120px!important}';
  document.head.appendChild(s);
})();true;`;

const FAQS = [
  { q: "Why does it say 'Access Denied'?", a: "The website occasionally limits access for security reasons. Give it 5–10 minutes and try again." },
  { q: 'What is this app for?', a: "An unofficial tool for Assurance Wireless users. No official app exists, so this wraps the MyAccount site in a cleaner experience. Fully vibecoded." },
  { q: 'Is this safe?', a: "Yes. The app loads the official Assurance Wireless website in a secure WebView. No data is collected or stored by this app." },
];

function isLoggedOut(url) {
  if (!url) return true;
  return url.includes('/login') || url === BASE || url === BASE+'/' || url.includes('/start') || url.includes('/logout') || !url.includes('/my-account');
}

function Icon({ name, active }) {
  const c = active ? '#fff' : 'rgba(255,255,255,0.45)';
  const p = { width:20, height:20, fill:'none', stroke:c, strokeWidth:'1.8', strokeLinecap:'round', strokeLinejoin:'round' };
  if (name==='Home')    return <Svg {...p} viewBox="0 0 24 24"><Path d="M3 9.5L12 3l9 6.5V20a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1z"/><Path d="M9 21V12h6v9"/></Svg>;
  if (name==='Usage')   return <Svg {...p} viewBox="0 0 24 24"><Path d="M18 20V10M12 20V4M6 20v-6"/></Svg>;
  if (name==='Add-Ons') return <Svg {...p} viewBox="0 0 24 24"><Circle cx="12" cy="12" r="9"/><Path d="M12 8v8M8 12h8"/></Svg>;
  if (name==='Alerts')  return <Svg {...p} viewBox="0 0 24 24"><Path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><Path d="M13.73 21a2 2 0 0 1-3.46 0"/></Svg>;
  if (name==='Profile') return <Svg {...p} viewBox="0 0 24 24"><Circle cx="12" cy="8" r="4"/><Path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></Svg>;
}

// ── YOUR NAV BTN (with activeBg overlay) ──
function NavBtn({ tab, index, active, onPress }) {
  const scale     = useRef(new Animated.Value(1)).current;
  const iconScale = useRef(new Animated.Value(1)).current;
  function handlePress() {
    Animated.sequence([
      Animated.timing(scale, { toValue:0.88, duration:80, useNativeDriver:true }),
      Animated.spring(scale, { toValue:1, friction:4, tension:200, useNativeDriver:true }),
    ]).start();
    Animated.sequence([
      Animated.timing(iconScale, { toValue:1.3, duration:100, useNativeDriver:true }),
      Animated.spring(iconScale, { toValue:1, friction:5, tension:200, useNativeDriver:true }),
    ]).start();
    onPress(index);
  }
  return (
    <TouchableOpacity onPress={handlePress} activeOpacity={1}>
      <Animated.View style={[s.btn, { transform:[{scale}] }]}>
        {active && <View style={s.activeBg}/>}
        <Animated.View style={{ transform:[{scale:iconScale}] }}>
          <Icon name={tab.label} active={active}/>
        </Animated.View>
        <Text style={[s.label, active && s.labelOn]}>{tab.label}</Text>
      </Animated.View>
    </TouchableOpacity>
  );
}

function PressBtn({ label, onPress, primary, dark }) {
  const scale = useRef(new Animated.Value(1)).current;
  function handlePress() {
    Animated.sequence([
      Animated.timing(scale, { toValue:0.97, duration:100, useNativeDriver:true }),
      Animated.spring(scale, { toValue:1, friction:5, useNativeDriver:true }),
    ]).start();
    setTimeout(onPress, 100);
  }
  return (
    <TouchableOpacity onPress={handlePress} activeOpacity={1}>
      <Animated.View style={[primary ? s.primaryBtn : [s.secondaryBtn, dark ? s.secDark : s.secLight], { transform:[{scale}] }]}>
        <Text style={primary ? s.primaryTxt : [s.secondaryTxt, { color: dark ? 'rgba(255,255,255,0.55)' : 'rgba(0,0,0,0.5)' }]}>{label}</Text>
      </Animated.View>
    </TouchableOpacity>
  );
}

// ── GRADIENT: each blob has its own independent loop with different durations/directions ──
function AnimatedGradient({ dark }) {
  const a1 = useRef(new Animated.Value(0)).current;
  const a2 = useRef(new Animated.Value(0)).current;
  const a3 = useRef(new Animated.Value(0)).current;

  function loop(val, dur, delay=0) {
    Animated.loop(Animated.sequence([
      Animated.delay(delay),
      Animated.timing(val, { toValue:1, duration:dur, easing:Easing.inOut(Easing.sin), useNativeDriver:false }),
      Animated.timing(val, { toValue:0, duration:dur, easing:Easing.inOut(Easing.sin), useNativeDriver:false }),
    ])).start();
  }

  useEffect(() => {
    loop(a1, 6000, 0);    // blob1: slowest
    loop(a2, 4200, 800);  // blob2: medium, offset start
    loop(a3, 5400, 1600); // blob3: medium-slow, offset more
  }, []);

  // Blob 1 — cyan top-left, drifts diagonally
  const b1t = a1.interpolate({ inputRange:[0,1], outputRange:[-100, 0] });
  const b1l = a1.interpolate({ inputRange:[0,1], outputRange:[-80, 10] });

  // Blob 2 — purple bottom-right, drifts up-left then back
  const b2b = a2.interpolate({ inputRange:[0,1], outputRange:[20, 120] });
  const b2r = a2.interpolate({ inputRange:[0,1], outputRange:[-60, 40] });

  // Blob 3 — cyan center, drifts right and slightly down
  const b3t = a3.interpolate({ inputRange:[0,1], outputRange:[height*0.25, height*0.45] });
  const b3l = a3.interpolate({ inputRange:[0,1], outputRange:[width*0.2, width*0.5] });

  return (
    <View style={[StyleSheet.absoluteFill, { backgroundColor: dark ? '#050d14' : '#f0f8ff', overflow:'hidden' }]}>
      <Animated.View style={{ position:'absolute', width:380, height:380, borderRadius:190, backgroundColor:CYAN,   opacity:dark?0.11:0.18, top:b1t, left:b1l }}/>
      <Animated.View style={{ position:'absolute', width:320, height:320, borderRadius:160, backgroundColor:PURPLE, opacity:dark?0.13:0.14, bottom:b2b, right:b2r }}/>
      <Animated.View style={{ position:'absolute', width:220, height:220, borderRadius:110, backgroundColor:CYAN,   opacity:dark?0.07:0.1,  top:b3t, left:b3l }}/>
    </View>
  );
}

function FAQModal({ visible, onClose, dark }) {
  const slideY = useRef(new Animated.Value(height)).current;
  const op     = useRef(new Animated.Value(0)).current;
  const [render, setRender] = useState(false);
  const [open, setOpen]     = useState(null);
  const heights = useRef(FAQS.map(() => new Animated.Value(0))).current;
  const rotates = useRef(FAQS.map(() => new Animated.Value(0))).current;

  useEffect(() => {
    if (visible) {
      setRender(true); op.setValue(0); slideY.setValue(height);
      Animated.parallel([
        Animated.timing(op, { toValue:1, duration:320, useNativeDriver:true }),
        Animated.spring(slideY, { toValue:0, friction:10, tension:80, useNativeDriver:true }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(op, { toValue:0, duration:250, useNativeDriver:true }),
        Animated.timing(slideY, { toValue:height, duration:300, easing:Easing.in(Easing.quad), useNativeDriver:true }),
      ]).start(() => { setRender(false); setOpen(null); });
    }
  }, [visible]);

  function toggle(i) {
    const next = open === i ? null : i;
    setOpen(next);
    FAQS.forEach((_, idx) => {
      Animated.spring(heights[idx], { toValue: next===idx ? 1 : 0, friction:10, tension:80, useNativeDriver:false }).start();
      Animated.timing(rotates[idx], { toValue: next===idx ? 1 : 0, duration:280, easing:Easing.inOut(Easing.quad), useNativeDriver:true }).start();
    });
  }

  if (!render) return null;

  const sheetBg   = dark ? '#0a0f1e' : '#ffffff';
  const titleCol  = dark ? '#fff'    : '#111';
  const qCol      = dark ? 'rgba(255,255,255,0.88)' : 'rgba(0,0,0,0.85)';
  const aCol      = dark ? 'rgba(255,255,255,0.5)'  : 'rgba(0,0,0,0.5)';
  const divCol    = dark ? 'rgba(255,255,255,0.07)'  : 'rgba(0,0,0,0.07)';
  const handleCol = dark ? 'rgba(255,255,255,0.15)'  : 'rgba(0,0,0,0.12)';
  const chevCol   = dark ? 'rgba(255,255,255,0.45)'  : 'rgba(0,0,0,0.35)';
  const borderCol = dark ? 'rgba(109,32,119,0.3)'    : 'rgba(0,174,239,0.2)';

  return (
    <Modal transparent animationType="none" visible={render}>
      <Animated.View style={[fS.overlay, { opacity:op }]}>
        <TouchableOpacity style={StyleSheet.absoluteFill} onPress={onClose} activeOpacity={1}/>
        <Animated.View style={[fS.sheet, { transform:[{translateY:slideY}], backgroundColor:sheetBg, borderColor:borderCol }]}>
          <View style={[fS.handle, { backgroundColor:handleCol }]}/>
          <View style={fS.sheetHeader}>
            <View style={fS.iconWrap}>
              <Svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke={CYAN} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <Circle cx="12" cy="12" r="10"/><Path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><Path d="M12 17h.01"/>
              </Svg>
            </View>
            <Text style={[fS.title, { color:titleCol }]}>Frequently Asked Questions</Text>
          </View>
          {FAQS.map((faq, i) => {
            const maxH = heights[i].interpolate({ inputRange:[0,1], outputRange:[0,160] });
            const rot  = rotates[i].interpolate({ inputRange:[0,1], outputRange:['0deg','180deg'] });
            return (
              <View key={i}>
                <TouchableOpacity onPress={() => toggle(i)} activeOpacity={0.75} style={fS.row}>
                  <Text style={[fS.q, { color:qCol }]}>{faq.q}</Text>
                  <Animated.View style={{ transform:[{rotate:rot}] }}>
                    <Svg width={16} height={16} viewBox="0 0 24 24" fill="none" stroke={chevCol} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                      <Path d="M6 9l6 6 6-6"/>
                    </Svg>
                  </Animated.View>
                </TouchableOpacity>
                <Animated.View style={{ overflow:'hidden', maxHeight:maxH, opacity:heights[i] }}>
                  <Text style={[fS.a, { color:aCol }]}>{faq.a}</Text>
                </Animated.View>
                {i < FAQS.length-1 && <View style={[fS.div, { backgroundColor:divCol }]}/>}
              </View>
            );
          })}
          <TouchableOpacity onPress={onClose} style={fS.closeBtn} activeOpacity={0.8}>
            <Text style={fS.closeTxt}>Got it</Text>
          </TouchableOpacity>
        </Animated.View>
      </Animated.View>
    </Modal>
  );
}

const fS = StyleSheet.create({
  overlay:     { flex:1, justifyContent:'flex-end', backgroundColor:'rgba(0,0,0,0.5)' },
  sheet:       { borderTopLeftRadius:28, borderTopRightRadius:28, paddingHorizontal:22, paddingBottom:40, borderWidth:1 },
  handle:      { width:38, height:4, borderRadius:2, alignSelf:'center', marginTop:12, marginBottom:6 },
  sheetHeader: { flexDirection:'row', alignItems:'center', gap:10, paddingVertical:16 },
  iconWrap:    { width:36, height:36, borderRadius:10, backgroundColor:'rgba(0,174,239,0.1)', alignItems:'center', justifyContent:'center' },
  title:       { fontSize:16, fontWeight:'700', flex:1 },
  row:         { flexDirection:'row', alignItems:'center', justifyContent:'space-between', paddingVertical:14, gap:12 },
  q:           { fontSize:13, fontWeight:'600', flex:1, lineHeight:18 },
  a:           { fontSize:13, lineHeight:20, paddingBottom:12 },
  div:         { height:1 },
  closeBtn:    { marginTop:16, backgroundColor:CYAN, borderRadius:999, paddingVertical:14, alignItems:'center' },
  closeTxt:    { color:'#fff', fontSize:15, fontWeight:'700' },
});

function RedirectModal({ visible, onConfirm, onCancel, dark }) {
  const scale = useRef(new Animated.Value(0.94)).current;
  const op    = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    if (visible) {
      Animated.parallel([
        Animated.timing(op, { toValue:1, duration:250, useNativeDriver:true }),
        Animated.spring(scale, { toValue:1, friction:8, tension:100, useNativeDriver:true }),
      ]).start();
    } else {
      Animated.timing(op, { toValue:0, duration:180, useNativeDriver:true }).start();
      scale.setValue(0.94);
    }
  }, [visible]);
  if (!visible) return null;
  const bg  = dark ? '#101826' : '#fff';
  const txt = dark ? '#fff'    : '#000';
  const sub = dark ? 'rgba(255,255,255,0.5)' : 'rgba(0,0,0,0.5)';
  const bor = dark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.12)';
  return (
    <Modal transparent animationType="none" visible={visible}>
      <Animated.View style={[s.modalOverlay, { opacity:op }]}>
        <Animated.View style={[s.modalCard, { transform:[{scale}], backgroundColor:bg }]}>
          <View style={s.modalIcon}>
            <Svg width={26} height={26} viewBox="0 0 24 24" fill="none" stroke={CYAN} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <Path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><Path d="M15 3h6v6"/><Path d="M10 14L21 3"/>
            </Svg>
          </View>
          <Text style={[s.modalTitle, { color:txt }]}>Opening in Browser</Text>
          <Text style={[s.modalBody, { color:sub }]}>You'll be redirected to the Assurance Wireless website in your browser to apply for service.</Text>
          <View style={s.modalBtns}>
            <TouchableOpacity onPress={onCancel} style={[s.modalCancel, { borderColor:bor }]} activeOpacity={0.7}>
              <Text style={[s.modalCancelTxt, { color:sub }]}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={onConfirm} style={s.modalConfirm} activeOpacity={0.7}>
              <Text style={s.modalConfirmTxt}>Open</Text>
            </TouchableOpacity>
          </View>
        </Animated.View>
      </Animated.View>
    </Modal>
  );
}

export default function App() {
  const scheme = useColorScheme();
  const dark   = scheme === 'dark';
  const [screen, setScreen]         = useState('splash');
  const [active, setActive]         = useState(0);
  const [loggedOut, setLoggedOut]   = useState(true);
  const [canGoBack, setCanGoBack]   = useState(false);
  const [webUrl, setWebUrl]         = useState(LOGIN_URL);
  const [showModal, setShowModal]   = useState(false);
  const [showFaq, setShowFaq]       = useState(false);
  const [navVisible, setNavVisible] = useState(false);
  const webRef    = useRef(null);
  const activeRef = useRef(0);

  const splashOp  = useRef(new Animated.Value(0)).current;
  const contentOp = useRef(new Animated.Value(0)).current;
  const contentY  = useRef(new Animated.Value(14)).current;
  const headerOp  = useRef(new Animated.Value(0)).current;
  const pillY     = useRef(new Animated.Value(80)).current;
  const pillSc    = useRef(new Animated.Value(0.92)).current;
  const pillOp    = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.timing(splashOp, { toValue:1, duration:450, useNativeDriver:true }).start();
    setTimeout(() => Animated.parallel([
      Animated.timing(contentOp, { toValue:1, duration:400, useNativeDriver:true }),
      Animated.spring(contentY, { toValue:0, friction:9, useNativeDriver:true }),
    ]).start(), 300);
  }, []);

  useEffect(() => {
    if (screen !== 'webview') return;
    Animated.timing(headerOp, { toValue:1, duration:350, delay:100, useNativeDriver:true }).start();
  }, [screen]);

  useEffect(() => {
    if (!loggedOut) {
      setNavVisible(true);
      pillY.setValue(80); pillSc.setValue(0.92); pillOp.setValue(0);
      Animated.parallel([
        Animated.timing(pillOp, { toValue:1, duration:450, delay:250, useNativeDriver:true }),
        Animated.spring(pillSc, { toValue:1, friction:8, tension:100, delay:250, useNativeDriver:true }),
        Animated.spring(pillY,  { toValue:0, friction:9, tension:100, delay:200, useNativeDriver:true }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(pillOp, { toValue:0, duration:220, useNativeDriver:true }),
        Animated.timing(pillY,  { toValue:80, duration:280, easing:Easing.in(Easing.quad), useNativeDriver:true }),
      ]).start(() => setNavVisible(false));
    }
  }, [loggedOut]);

  function openWebView(url) {
    setWebUrl(url);
    Animated.timing(splashOp, { toValue:0, duration:260, useNativeDriver:true }).start(() => setScreen('webview'));
  }

  function goBackOrSplash() {
    if (canGoBack) {
      webRef.current?.goBack();
    } else {
      setScreen('splash'); setLoggedOut(true); setCanGoBack(false); headerOp.setValue(0);
      Animated.timing(splashOp, { toValue:1, duration:300, useNativeDriver:true }).start();
    }
  }

  function goTo(i) {
    setActive(i); activeRef.current = i;
    webRef.current?.injectJavaScript(`window.location.href='${TABS[i].url}';true;`);
  }

  function onNavChange(nav) {
    const url = nav.url;
    setCanGoBack(nav.canGoBack);
    const out = isLoggedOut(url);
    setLoggedOut(out);
    if (!out) {
      const i = TABS.findIndex(t => url.includes(t.match));
      if (i !== -1 && i !== activeRef.current) { setActive(i); activeRef.current = i; }
    }
  }

  if (screen === 'splash') {
    return (
      <View style={s.splashRoot}>
        <StatusBar barStyle={dark ? 'light-content' : 'dark-content'} backgroundColor="transparent" translucent/>
        <AnimatedGradient dark={dark}/>
        <Animated.View style={[StyleSheet.absoluteFill, { opacity:splashOp }]}>
          <SafeAreaView style={s.splashSafe}>
            <TouchableOpacity onPress={() => setShowFaq(true)} style={[s.helpBtn, { backgroundColor: dark ? 'rgba(0,174,239,0.1)' : 'rgba(0,174,239,0.08)', borderColor: dark ? 'rgba(0,174,239,0.2)' : 'rgba(0,174,239,0.25)' }]} activeOpacity={0.8}>
              <Svg width={16} height={16} viewBox="0 0 24 24" fill="none" stroke={CYAN} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <Circle cx="12" cy="12" r="10"/><Path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><Path d="M12 17h.01"/>
              </Svg>
              <Text style={[s.helpTxt, { color: dark ? 'rgba(255,255,255,0.55)' : 'rgba(0,0,0,0.5)' }]}>Help</Text>
            </TouchableOpacity>
            <View style={s.splashLogoWrap}>
              <Image source={LOGO_SPLASH} style={s.splashLogo} resizeMode="contain"/>
            </View>
            <Animated.View style={[s.splashBottom, { opacity:contentOp, transform:[{translateY:contentY}] }]}>
              <Text style={[s.tagline, { color: dark ? 'rgba(255,255,255,0.4)' : 'rgba(0,0,0,0.4)' }]}>
                Get FREE Monthly Lifeline Service on T-Mobile
              </Text>
              <PressBtn label="Sign In" primary dark={dark} onPress={() => openWebView(LOGIN_URL)}/>
              <View style={{ height:12 }}/>
              <PressBtn label="Get Service" dark={dark} onPress={() => setShowModal(true)}/>
            </Animated.View>
          </SafeAreaView>
        </Animated.View>
        <FAQModal visible={showFaq} onClose={() => setShowFaq(false)} dark={dark}/>
        <RedirectModal visible={showModal} dark={dark} onCancel={() => setShowModal(false)} onConfirm={() => { setShowModal(false); Linking.openURL(SIGNUP_URL); }}/>
      </View>
    );
  }

  return (
    <View style={[s.root, { backgroundColor: dark ? '#000' : '#fff' }]}>
      <StatusBar barStyle="light-content" backgroundColor={CYAN}/>
      <Animated.View style={[s.topBar, { opacity:headerOp }]}>
        <SafeAreaView style={{ backgroundColor:CYAN }}>
          <View style={s.topRow}>
            <TouchableOpacity onPress={goBackOrSplash} activeOpacity={0.7} style={s.backBtn}>
              <Svg width={18} height={18} viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <Path d="M15 18l-6-6 6-6"/>
              </Svg>
            </TouchableOpacity>
            <Image source={{ uri:LOGO_HEADER }} style={s.headerLogo} resizeMode="contain"/>
            <View style={{ width:36 }}/>
          </View>
        </SafeAreaView>
        <View style={s.purpleLine}/>
      </Animated.View>

      <View style={{ flex:1 }}>
        <WebView ref={webRef} source={{ uri:webUrl }} style={s.web} javaScriptEnabled domStorageEnabled onNavigationStateChange={onNavChange} onLoadEnd={() => webRef.current?.injectJavaScript(INJECTED_CSS)}/>
      </View>

      {/* YOUR NAV BAR — activeBg per button, glass pill */}
      {navVisible && (
        <Animated.View style={[s.pillWrap, { opacity:pillOp, transform:[{translateY:pillY},{scale:pillSc}] }]}>
          <View style={s.glassOuter}>
            <View style={s.glassInner}>
              <View style={s.pillShine}/>
              <View style={s.row}>
                {TABS.map((tab, i) => (
                  <NavBtn key={tab.label} tab={tab} index={i} active={i===active} onPress={goTo}/>
                ))}
              </View>
            </View>
          </View>
        </Animated.View>
      )}
    </View>
  );
}

const GLASS = 'rgba(22,22,32,0.82)';
const s = StyleSheet.create({
  splashRoot:    { flex:1 },
  splashSafe:    { flex:1, alignItems:'center', justifyContent:'space-between', paddingTop:60, paddingBottom:52, paddingHorizontal:32 },
  splashLogoWrap:{ flex:1, alignItems:'center', justifyContent:'center', width:'100%' },
  splashLogo:    { width:width*0.68, height:90 },
  splashBottom:  { width:'100%', alignItems:'center' },
  helpBtn:       { position:'absolute', top:65, right:20, flexDirection:'row', alignItems:'center', gap:5, paddingHorizontal:12, paddingVertical:7, borderRadius:999, borderWidth:1 },
  helpTxt:       { fontSize:12, fontWeight:'600' },
  tagline:       { fontSize:14, marginBottom:26, letterSpacing:0.3, textAlign:'center' },
  primaryBtn:    { width:width-64, backgroundColor:CYAN, borderRadius:999, paddingVertical:15, alignItems:'center', shadowColor:CYAN, shadowOffset:{width:0,height:6}, shadowOpacity:0.35, shadowRadius:14 },
  primaryTxt:    { color:'#fff', fontSize:16, fontWeight:'700' },
  secondaryBtn:  { width:width-64, borderRadius:999, paddingVertical:14, alignItems:'center', borderWidth:1 },
  secDark:       { borderColor:'rgba(255,255,255,0.18)' },
  secLight:      { borderColor:'rgba(0,0,0,0.15)' },
  secondaryTxt:  { fontSize:15, fontWeight:'500' },
  modalOverlay:  { flex:1, backgroundColor:'rgba(0,0,0,0.5)', alignItems:'center', justifyContent:'center', padding:32 },
  modalCard:     { borderRadius:22, padding:28, width:'100%', alignItems:'center', shadowColor:'#000', shadowOffset:{width:0,height:12}, shadowOpacity:0.2, shadowRadius:24 },
  modalIcon:     { width:52, height:52, borderRadius:14, backgroundColor:'rgba(0,174,239,0.1)', alignItems:'center', justifyContent:'center', marginBottom:14 },
  modalTitle:    { fontSize:17, fontWeight:'700', marginBottom:8 },
  modalBody:     { fontSize:14, textAlign:'center', lineHeight:20, marginBottom:24 },
  modalBtns:     { flexDirection:'row', gap:12, width:'100%' },
  modalCancel:   { flex:1, paddingVertical:13, borderRadius:999, borderWidth:1, alignItems:'center' },
  modalCancelTxt:{ fontSize:15, fontWeight:'500' },
  modalConfirm:  { flex:1, paddingVertical:13, borderRadius:999, backgroundColor:CYAN, alignItems:'center' },
  modalConfirmTxt:{ fontSize:15, fontWeight:'700', color:'#fff' },
  root:          { flex:1 },
  topBar:        { backgroundColor:CYAN, zIndex:10, paddingTop: Platform.OS==='android' ? StatusBar.currentHeight : 0 },
  topRow:        { flexDirection:'row', alignItems:'center', justifyContent:'space-between', paddingHorizontal:12, paddingVertical:6 },
  backBtn:       { width:34, height:34, borderRadius:17, backgroundColor:'rgba(255,255,255,0.15)', alignItems:'center', justifyContent:'center' },
  headerLogo:    { width:150, height:36 },
  purpleLine:    { height:3, backgroundColor:PURPLE },
  web:           { flex:1 },
  pillWrap:      { position:'absolute', bottom:36, left:0, right:0, alignItems:'center' },
  glassOuter:    { borderRadius:999, borderWidth:1, borderColor:'rgba(255,255,255,0.22)', shadowColor:'#000', shadowOffset:{width:0,height:8}, shadowOpacity:0.3, shadowRadius:20, elevation:20 },
  glassInner:    { borderRadius:999, backgroundColor:GLASS, overflow:'hidden', padding:5 },
  pillShine:     { position:'absolute', top:0, left:20, right:20, height:1, backgroundColor:'rgba(255,255,255,0.28)', borderRadius:999 },
  row:           { flexDirection:'row', gap:2 },
  // YOUR exact btn + activeBg styles
  btn:           { alignItems:'center', justifyContent:'center', paddingVertical:9, paddingHorizontal:11, borderRadius:999, minWidth:58, gap:3, position:'relative' },
  activeBg:      { position:'absolute', top:0, bottom:0, left:0, right:0, borderRadius:999, backgroundColor:'rgba(255,255,255,0.15)', borderWidth:0.5, borderColor:'rgba(255,255,255,0.22)' },
  label:         { fontSize:9, fontWeight:'500', color:'rgba(255,255,255,0.4)', letterSpacing:0.2 },
  labelOn:       { color:'#fff' },
});