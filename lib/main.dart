import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:paywise/models/app_state.dart';
import 'package:paywise/redux/state/store.dart';
import 'package:paywise/screens/routes.dart';
import 'dart:core';
import 'package:paywise/themes/app_theme.dart';
import 'package:paywise/themes/custom_theme.dart';
import 'package:redux/redux.dart';
import 'package:flutter/foundation.dart';
import 'package:paywise/generated/i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

void main() async {
  await DotEnv().load('.env_paywise');
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]).then((_) async {
    runApp(CustomTheme(
      initialThemeKey: MyThemeKeys.PAYWISE,
      child: new MyApp(
          store: await AppFactory().getStore(),
       ),
    ));
  });

}

class MyApp extends StatefulWidget {
  final Store<AppState> store;

  MyApp({Key key, this.store}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState(store);
}

class _MyAppState extends State<MyApp> {
  Store<AppState> store;
  _MyAppState(this.store);
  final i18n = I18n.delegate;

  void onLocaleChange(Locale locale) {
    setState(() {
      I18n.locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    I18n.onLocaleChanged = onLocaleChange;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark
        .copyWith(statusBarIconBrightness: Brightness.dark));
    return new Column(
      children: <Widget>[
        new Expanded(
          child: new StoreProvider<AppState>(
            store: store,
            child: new MaterialApp(
              title: 'Fuse Cash',
              initialRoute: '/',
              routes: getRoutes(),
              theme: CustomTheme.of(context),
              localizationsDelegates: [
                i18n,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: i18n.supportedLocales,
              localeResolutionCallback:
                  i18n.resolution(fallback: new Locale("en", "US")),
            ),
          ),
        ),
      ],
    );
  }
}
