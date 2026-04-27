import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const AssuranceApp());
}

const String kLoginUrl   = 'https://myaccount.assurancewireless.com/login/start';
const String kSignupUrl  = 'https://www.assurancewireless.com/';
const String kBase       = 'https://myaccount.assurancewireless.com';
const Color  kCyan       = Color(0xFF00AEEF);
const Color  kPurple     = Color(0xFF6D2077);
const String kLogoHeader = 'https://freeimage.host/images/2024/BrzIqiB.png';

const String kInjectedCss = """
(function(){
  var s=document.createElement('style');
  s.innerHTML='.site-header,.app-header,.main-header,[class*="TopNav"],[class*="top-nav"],[class*="SiteNav"],[class*="site-nav"],[id="header"],[id="site-header"],.footer-wrapper,.site-footer,.main-footer,[id="footer"]{display:none!important}body{padding-bottom:120px!important}';
  document.head.appendChild(s);
})();true;
""";

final List<TabItem> kTabs = [
  TabItem(label: 'Home',    url: '$kBase/my-account/dashboard',       match: 'dashboard'),
  TabItem(label: 'Usage',   url: '$kBase/my-account/usage-history',   match: 'usage'),
  TabItem(label: 'Add-Ons', url: '$kBase/my-account/select-services', match: 'select-services'),
  TabItem(label: 'Alerts',  url: '$kBase/my-account/notifications',   match: 'notification'),
  TabItem(label: 'Profile', url: '$kBase/my-account/profile',         match: 'profile'),
];

const List<Map<String, String>> kFaqs = [
  {
    'q': "Why does it say 'Access Denied'?",
    'a': "The website occasionally limits access for security reasons. Give it 5–10 minutes and try again.",
  },
  {
    'q': 'What is this app for?',
    'a': "An unofficial tool for Assurance Wireless users. No official app exists, so this wraps the MyAccount site in a cleaner experience. Fully vibecoded.",
  },
  {
    'q': 'Is this safe?',
    'a': "Yes. The app loads the official Assurance Wireless website in a secure WebView. No data is collected or stored by this app.",
  },
];

class TabItem {
  final String label, url, match;
  const TabItem({required this.label, required this.url, required this.match});
}

bool isLoggedOut(String? url) {
  if (url == null) return true;
  return url.contains('/login') ||
      url == kBase ||
      url == '$kBase/' ||
      url.contains('/start') ||
      url.contains('/logout') ||
      !url.contains('/my-account');
}

// ── Root App ───────────────────────────────────────────────────────────────────
class AssuranceApp extends StatelessWidget {
  const AssuranceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assurance Wireless',
      debugShowCheckedModeBanner: false,
      theme:     ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark,  useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}

// ── App Shell ──────────────────────────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _screen = 'splash';
  void _openWebView() => setState(() => _screen = 'webview');
  void _goToSplash()  => setState(() => _screen = 'splash');
  @override
  Widget build(BuildContext context) {
    if (_screen == 'splash') return SplashScreen(onSignIn: _openWebView);
    return WebViewScreen(onBack: _goToSplash);
  }
}

// ── Splash Screen ──────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  final VoidCallback onSignIn;
  const SplashScreen({super.key, required this.onSignIn});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _contentFade;
  late Animation<Offset>  _contentSlide;
  bool _showRedirectModal = false;
  bool _showFaq           = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim    = CurvedAnimation(parent: _fadeCtrl,    curve: Curves.easeIn);
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeIn);
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final w    = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedGradientBackground(dark: dark),
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 12, right: 16,
                    child: _HelpButton(dark: dark, onTap: () => setState(() => _showFaq = true)),
                  ),
                  Column(
                    children: [
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _LogoPlaceholder(width: w * 0.68),
                      ),
                      const Spacer(),
                      SlideTransition(
                        position: _contentSlide,
                        child: FadeTransition(
                          opacity: _contentFade,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(32, 0, 32, 52),
                            child: Column(
                              children: [
                                Text(
                                  'Get FREE Monthly Lifeline Service on T-Mobile',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    letterSpacing: 0.3,
                                    color: dark
                                        ? Colors.white.withOpacity(0.4)
                                        : Colors.black.withOpacity(0.4),
                                  ),
                                ),
                                const SizedBox(height: 26),
                                _PressButton(label: 'Sign In',     primary: true,  dark: dark, onPressed: widget.onSignIn),
                                const SizedBox(height: 12),
                                _PressButton(label: 'Get Service', primary: false, dark: dark, onPressed: () => setState(() => _showRedirectModal = true)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_showFaq)
            FaqModal(dark: dark, onClose: () => setState(() => _showFaq = false)),
          if (_showRedirectModal)
            RedirectModal(
              dark: dark,
              onCancel:  () => setState(() => _showRedirectModal = false),
              onConfirm: () {
                setState(() => _showRedirectModal = false);
                launchUrl(Uri.parse(kSignupUrl), mode: LaunchMode.externalApplication);
              },
            ),
        ],
      ),
    );
  }
}

// ── WebView Screen ─────────────────────────────────────────────────────────────
class WebViewScreen extends StatefulWidget {
  final VoidCallback onBack;
  const WebViewScreen({super.key, required this.onBack});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with TickerProviderStateMixin {
  late WebViewController _controller;
  int  _activeTab  = 0;
  bool _navVisible = false;

  late AnimationController _headerCtrl;
  late AnimationController _pillCtrl;
  late Animation<double>   _headerFade;
  late Animation<double>   _pillFade;
  late Animation<Offset>   _pillSlide;
  late Animation<double>   _pillScale;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _pillCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn);
    _pillFade   = CurvedAnimation(parent: _pillCtrl,   curve: Curves.easeOut);
    _pillSlide  = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pillCtrl, curve: Curves.easeOut));
    _pillScale  = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _pillCtrl, curve: Curves.elasticOut));

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _controller.runJavaScript(kInjectedCss),
        onUrlChange: (change) {
          final url = change.url ?? '';
          final out = isLoggedOut(url);
          if (!out) {
            final i = kTabs.indexWhere((t) => url.contains(t.match));
            if (i != -1 && i != _activeTab) setState(() => _activeTab = i);
            _showNav();
          } else {
            _hideNav();
          }
        },
      ))
      ..loadRequest(Uri.parse(kLoginUrl));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _headerCtrl.forward();
    });
  }

  void _showNav() {
    if (_navVisible) return;
    setState(() => _navVisible = true);
    _pillCtrl.forward(from: 0);
  }

  void _hideNav() {
    if (!_navVisible) return;
    _pillCtrl.reverse().then((_) {
      if (mounted) setState(() => _navVisible = false);
    });
  }

  void _goTo(int i) {
    setState(() => _activeTab = i);
    _controller.runJavaScript("window.location.href='${kTabs[i].url}';true;");
  }

  Future<void> _goBackOrSplash() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else {
      widget.onBack();
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _pillCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? Colors.black : Colors.white,
      body: Column(
        children: [
          FadeTransition(opacity: _headerFade, child: _TopBar(onBack: _goBackOrSplash)),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _navVisible
          ? FadeTransition(
              opacity: _pillFade,
              child: SlideTransition(
                position: _pillSlide,
                child: ScaleTransition(
                  scale: _pillScale,
                  child: _NavPill(activeIndex: _activeTab, onTabPressed: _goTo),
                ),
              ),
            )
          : null,
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final Future<void> Function() onBack;
  const _TopBar({required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: kCyan,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                    ),
                  ),
                  const Spacer(),
                  Image.network(
                    kLogoHeader,
                    width: 150, height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      'Assurance Wireless',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 34),
                ],
              ),
            ),
          ),
        ),
        Container(height: 3, color: kPurple),
      ],
    );
  }
}

// ── Nav Pill ───────────────────────────────────────────────────────────────────
class _NavPill extends StatelessWidget {
  final int activeIndex;
  final void Function(int) onTabPressed;
  const _NavPill({required this.activeIndex, required this.onTabPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kCyan.withOpacity(0.82),
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.all(5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(kTabs.length, (i) => _NavBtn(
            tab: kTabs[i],
            active: i == activeIndex,
            onTap: () => onTabPressed(i),
          )),
        ),
      ),
    );
  }
}

class _NavBtn extends StatefulWidget {
  final TabItem tab;
  final bool active;
  final VoidCallback onTap;
  const _NavBtn({required this.tab, required this.active, required this.onTap});
  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onTap() async {
    await _ctrl.forward();
    _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.active ? Colors.white : Colors.white.withOpacity(0.45);
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 11),
          constraints: const BoxConstraints(minWidth: 58),
          decoration: BoxDecoration(
            color: widget.active ? kPurple.withOpacity(0.85) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TabIcon(name: widget.tab.label, color: iconColor),
              const SizedBox(height: 3),
              Text(
                widget.tab.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: widget.active ? Colors.white : Colors.white.withOpacity(0.4),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  final String name;
  final Color color;
  const _TabIcon({required this.name, required this.color});
  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (name) {
      case 'Home':    icon = Icons.home_outlined;         break;
      case 'Usage':   icon = Icons.bar_chart;             break;
      case 'Add-Ons': icon = Icons.add_circle_outline;    break;
      case 'Alerts':  icon = Icons.notifications_outlined; break;
      case 'Profile': icon = Icons.person_outline;        break;
      default:        icon = Icons.circle_outlined;
    }
    return Icon(icon, color: color, size: 20);
  }
}

// ── Animated Gradient Background ───────────────────────────────────────────────
class AnimatedGradientBackground extends StatefulWidget {
  final bool dark;
  const AnimatedGradientBackground({super.key, required this.dark});
  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _c1, _c2, _c3;

  @override
  void initState() {
    super.initState();
    _c1 = _loop(const Duration(milliseconds: 6000));
    _c2 = _loop(const Duration(milliseconds: 4200), delay: const Duration(milliseconds: 800));
    _c3 = _loop(const Duration(milliseconds: 5400), delay: const Duration(milliseconds: 1600));
  }

  AnimationController _loop(Duration dur, {Duration delay = Duration.zero}) {
    final c = AnimationController(vsync: this, duration: dur);
    Future.delayed(delay, () { if (mounted) c.repeat(reverse: true); });
    return c;
  }

  @override
  void dispose() { _c1.dispose(); _c2.dispose(); _c3.dispose(); super.dispose(); }

  double lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final s  = MediaQuery.of(context).size;
    final bg = widget.dark ? const Color(0xFF050D14) : const Color(0xFFF0F8FF);
    return AnimatedBuilder(
      animation: Listenable.merge([_c1, _c2, _c3]),
      builder: (_, __) => Container(
        color: bg,
        child: Stack(
          children: [
            Positioned(
              top:  lerp(-100, 0,  _c1.value),
              left: lerp(-80,  10, _c1.value),
              child: _Blob(380, kCyan,   widget.dark ? 0.11 : 0.18),
            ),
            Positioned(
              bottom: lerp(20,  120, _c2.value),
              right:  lerp(-60, 40,  _c2.value),
              child: _Blob(320, kPurple, widget.dark ? 0.13 : 0.14),
            ),
            Positioned(
              top:  lerp(s.height * 0.25, s.height * 0.45, _c3.value),
              left: lerp(s.width  * 0.2,  s.width  * 0.5,  _c3.value),
              child: _Blob(220, kCyan,   widget.dark ? 0.07 : 0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size, opacity;
  final Color color;
  const _Blob(this.size, this.color, this.opacity);
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity)),
  );
}

class _LogoPlaceholder extends StatelessWidget {
  final double width;
  const _LogoPlaceholder({required this.width});
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Assurance_Wireless_logo.png',
      width: width,
      height: 90,
      fit: BoxFit.contain,
    );
  }
}

// ── Help Button ────────────────────────────────────────────────────────────────
class _HelpButton extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;
  const _HelpButton({required this.dark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:        dark ? kCyan.withOpacity(0.1) : kCyan.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border:       Border.all(color: dark ? kCyan.withOpacity(0.2) : kCyan.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline, color: kCyan, size: 16),
            const SizedBox(width: 5),
            Text(
              'Help',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Press Button ───────────────────────────────────────────────────────────────
class _PressButton extends StatefulWidget {
  final String label;
  final bool primary, dark;
  final VoidCallback onPressed;
  const _PressButton({required this.label, required this.primary, this.dark = false, required this.onPressed});
  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onTap() async {
    await _ctrl.forward();
    _ctrl.reverse();
    Future.delayed(const Duration(milliseconds: 100), widget.onPressed);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width - 64;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _onTap,
        child: widget.primary
            ? Container(
                width: w,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: kCyan,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [BoxShadow(color: kCyan.withOpacity(0.35), offset: const Offset(0, 6), blurRadius: 14)],
                ),
                alignment: Alignment.center,
                child: const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              )
            : Container(
                width: w,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: widget.dark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.15),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: widget.dark ? Colors.white.withOpacity(0.55) : Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── FAQ Modal ──────────────────────────────────────────────────────────────────
class FaqModal extends StatefulWidget {
  final bool dark;
  final VoidCallback onClose;
  const FaqModal({super.key, required this.dark, required this.onClose});
  @override
  State<FaqModal> createState() => _FaqModalState();
}

class _FaqModalState extends State<FaqModal> with TickerProviderStateMixin {
  late AnimationController _sheetCtrl;
  late Animation<double>   _sheetFade;
  late Animation<Offset>   _sheetSlide;
  int? _openIndex;
  late List<AnimationController> _itemCtrls;

  @override
  void initState() {
    super.initState();
    _sheetCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _sheetFade  = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeIn);
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));
    _itemCtrls  = List.generate(kFaqs.length,
        (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 280)));
    _sheetCtrl.forward();
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    for (final c in _itemCtrls) c.dispose();
    super.dispose();
  }

  void _toggle(int i) {
    setState(() {
      if (_openIndex == i) {
        _openIndex = null;
        _itemCtrls[i].reverse();
      } else {
        if (_openIndex != null) _itemCtrls[_openIndex!].reverse();
        _openIndex = i;
        _itemCtrls[i].forward();
      }
    });
  }

  void _close() => _sheetCtrl.reverse().then((_) => widget.onClose());

  @override
  Widget build(BuildContext context) {
    final dark     = widget.dark;
    final sheetBg  = dark ? const Color(0xFF0A0F1E) : Colors.white;
    final titleCol = dark ? Colors.white : const Color(0xFF111111);
    final qCol     = dark ? Colors.white.withOpacity(0.88) : Colors.black.withOpacity(0.85);
    final aCol     = dark ? Colors.white.withOpacity(0.5)  : Colors.black.withOpacity(0.5);
    final divCol   = dark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);

    return FadeTransition(
      opacity: _sheetFade,
      child: GestureDetector(
        onTap: _close,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: SlideTransition(
              position: _sheetSlide,
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: dark ? kPurple.withOpacity(0.3) : kCyan.withOpacity(0.2),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38, height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 6),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: kCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.help_outline, color: kCyan, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text('Frequently Asked Questions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: titleCol)),
                        ],
                      ),
                    ),
                    ...List.generate(kFaqs.length, (i) {
                      final rot = Tween<double>(begin: 0, end: math.pi)
                          .animate(CurvedAnimation(parent: _itemCtrls[i], curve: Curves.easeInOut));
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () => _toggle(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(kFaqs[i]['q']!,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: qCol)),
                                  ),
                                  const SizedBox(width: 12),
                                  AnimatedBuilder(
                                    animation: rot,
                                    builder: (_, __) => Transform.rotate(
                                      angle: rot.value,
                                      child: Icon(Icons.keyboard_arrow_down,
                                          color: dark ? Colors.white.withOpacity(0.45) : Colors.black.withOpacity(0.35),
                                          size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizeTransition(
                            sizeFactor: CurvedAnimation(parent: _itemCtrls[i], curve: Curves.easeOut),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(kFaqs[i]['a']!,
                                  style: TextStyle(fontSize: 13, height: 1.55, color: aCol)),
                            ),
                          ),
                          if (i < kFaqs.length - 1) Divider(height: 1, color: divCol),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _close,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: kCyan, borderRadius: BorderRadius.circular(999)),
                        alignment: Alignment.center,
                        child: const Text('Got it',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Redirect Modal ─────────────────────────────────────────────────────────────
class RedirectModal extends StatefulWidget {
  final bool dark;
  final VoidCallback onCancel, onConfirm;
  const RedirectModal({super.key, required this.dark, required this.onCancel, required this.onConfirm});
  @override
  State<RedirectModal> createState() => _RedirectModalState();
}

class _RedirectModalState extends State<RedirectModal> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade, _scale;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final bg   = dark ? const Color(0xFF101826) : Colors.white;
    final txt  = dark ? Colors.white : Colors.black;
    final sub  = dark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5);
    final bor  = dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.12);

    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 12))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: kCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.open_in_new, color: kCyan, size: 26),
                  ),
                  const SizedBox(height: 14),
                  Text('Opening in Browser',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: txt)),
                  const SizedBox(height: 8),
                  Text(
                    "You'll be redirected to the Assurance Wireless website in your browser to apply for service.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.45, color: sub),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onCancel,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: bor)),
                            alignment: Alignment.center,
                            child: Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: sub)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onConfirm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(color: kCyan, borderRadius: BorderRadius.circular(999)),
                            alignment: Alignment.center,
                            child: const Text('Open',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}