// Flutter
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Internal
import 'package:songtube/internal/nativeMethods.dart';
import 'package:songtube/internal/playerService.dart';
import 'package:songtube/provider/managerProvider.dart';
import 'package:songtube/screens/downloads.dart';
import 'package:songtube/screens/home.dart';
import 'package:songtube/screens/more.dart';
import 'package:songtube/screens/musicPlayer/screenStateStream.dart';
import 'package:songtube/screens/navigate.dart';

// Packages
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

// UI
import 'package:songtube/screens/musicPlayer.dart';
import 'package:songtube/ui/snackbar.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class Library extends StatefulWidget {
  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> with WidgetsBindingObserver, TickerProviderStateMixin {

  // TabBar Controller
  TabController tabController;

  // Library Screens
  List<Widget> screens = [
    HomeScreen(),
    DownloadTab(),
    Navigate(),
    MoreScreen()
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.renderView.automaticSystemUiAdjustment=false;
    KeyboardVisibility.onChange.listen((bool visible) {
        if (visible == false) FocusScope.of(context).unfocus();
      }
    );
    tabController = new TabController(
      initialIndex: 0,
      length: screens.length,
      vsync: this
    );
    tabController.animation.addListener(() {
      int value = tabController.animation.value.round();
      if (value != tabController.index)
        setState(() => tabController.index = value);
    });
    Provider.of<ManagerProvider>(context, listen: false).screenIndex.listen((value) {
      setState(() {
        tabController.index = value;
      });
    });
    ManagerProvider provider =
      Provider.of<ManagerProvider>(context, listen: false);
    provider.downloadInfoSetList.forEach((element) {
      element.currentAction.stream.listen((event) {
        if (event == "Completed") {
          provider.getDatabase();
          setState(() {});
        }
        if (event == "Access Denied") {
          setState(() {});
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      String _url; String _id;
      await NativeMethod.handleIntent().then((resultText) => _url = resultText);
      if (_url == null) return;
      _id = yt.VideoId.parseVideoId(_url);
      if (_id == null) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ManagerProvider manager = Provider.of<ManagerProvider>(context);
    Brightness _themeBrightness = Theme.of(context).brightness;
    Brightness _systemBrightness = Theme.of(context).brightness;
    Brightness _statusBarBrightness = _systemBrightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: _statusBarBrightness,
        statusBarIconBrightness: _statusBarBrightness,
        systemNavigationBarColor: Theme.of(context).cardColor,
        systemNavigationBarIconBrightness: _themeBrightness
      ),
    );
    manager.snackBar = new AppSnack(scaffoldKey: manager.libraryScaffoldKey, context: context);
    return Material(
      child: Stack(
        children: [
          tabBarView(context),
          SlidingPlayerPanel()
        ],
      )
    );
  }

  Widget tabBarView(BuildContext context) {
    ManagerProvider manager = Provider.of<ManagerProvider>(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        key: manager.libraryScaffoldKey,
        resizeToAvoidBottomInset:
          manager.mediaStreamReady == false ? false : true,
        body: SafeArea(
          child: WillPopScope(
            onWillPop: () => manager.handlePop(tabController.index),
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (OverscrollIndicatorNotification overscroll) {
                overscroll.disallowGlow();
                return;
              },
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      children: screens,
                    ),
                  ),
                  playerPadding(context)
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(                                                   
            borderRadius: BorderRadius.only(                                           
              topRight: Radius.circular(30),
              topLeft: Radius.circular(30)
            ),
            boxShadow: [                                                               
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                spreadRadius: 0.1,
                blurRadius: 10
              ),
            ],                                                                         
          ), 
          child: BottomNavigationBar(
            backgroundColor: Theme.of(context).cardColor,
            currentIndex: tabController.index,
            selectedFontSize: 14,
            elevation: 8,
            selectedItemColor: Theme.of(context).accentColor,
            unselectedItemColor: Theme.of(context).iconTheme.color,
            type: BottomNavigationBarType.fixed,
            onTap: (int index) {
              manager.screenIndex.add(index);
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(EvaIcons.homeOutline),
                title: Text("Home", style: TextStyle(
                  fontFamily: "Varela",
                  fontWeight: FontWeight.w600
                )),
              ),
              BottomNavigationBarItem(
                icon: Icon(EvaIcons.cloudDownloadOutline),
                title: Text("Downloads", style: TextStyle(
                  fontFamily: "Varela",
                  fontWeight: FontWeight.w600
                )),
              ),
              BottomNavigationBarItem(
                icon: Icon(EvaIcons.browserOutline),
                title: Text("YouTube", style: TextStyle(
                  fontFamily: "Varela",
                  fontWeight: FontWeight.w600
                )),
              ),
              BottomNavigationBarItem(
                icon: Icon(MdiIcons.dotsHorizontal),
                title: Text("More", style: TextStyle(
                  fontFamily: "Varela",
                  fontWeight: FontWeight.w600
                )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget playerPadding(BuildContext context) {
    return StreamBuilder<ScreenState>(
      stream: screenStateStream,
      builder: (context, snapshot) {
        final screenState = snapshot.data;
        final state = screenState?.playbackState;
        final processingState =
          state?.processingState ?? AudioProcessingState.none;
        return Container(
          height: processingState != AudioProcessingState.none
            ? kToolbarHeight * 1.15
            : 0
        );
      }
    );
  }

}