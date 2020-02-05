import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paywise/generated/i18n.dart';
import 'package:paywise/models/app_state.dart';
import 'package:paywise/models/transaction.dart';
import 'package:paywise/models/views/contacts.dart';
import 'package:paywise/screens/cash_home/cash_transactions.dart';
import 'package:paywise/screens/send/enable_contacts.dart';
import 'package:paywise/screens/send/send_amount_arguments.dart';
import 'package:paywise/utils/contacts.dart';
import 'package:paywise/utils/format.dart';
import 'package:paywise/utils/phone.dart';
import 'package:paywise/widgets/bottombar.dart';
import 'package:paywise/widgets/main_scaffold.dart';
import 'package:redux/redux.dart';
import "package:ethereum_address/ethereum_address.dart";
import 'dart:math' as math;

typedef OnSignUpCallback = Function(String countryCode, String phoneNumber);

class SendToContactScreen extends StatefulWidget {
  final ContactsViewModel viewModel;

  SendToContactScreen(this.viewModel);

  @override
  _SendToContactScreenState createState() => _SendToContactScreenState();
}

class _SendToContactScreenState extends State<SendToContactScreen> {
  List<Contact> userList = [];
  List<Contact> filteredUsers = [];
  bool showFooter = true;
  TextEditingController searchController = TextEditingController();
  bool isPreloading = false;

  loadContacts() {
    if (this.mounted) {
      setState(() {
        isPreloading = true;
      });
    }
    for (var contact in this.widget.viewModel.contacts) {
      userList.add(contact);
    }
    userList.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    filterList();
    searchController.addListener(() {
      filterList();
    });

    if (this.mounted) {
      setState(() {
        isPreloading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  void _onFocusChange(hasFocus) {
    if (mounted) {
      setState(() {
        showFooter = !hasFocus;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  filterList() {
    List<Contact> users = [];
    users.addAll(userList);
    if (searchController.text.isNotEmpty) {
      users.retainWhere((user) => user.displayName
          .toLowerCase()
          .contains(searchController.text.toLowerCase()));
    }

    if (this.mounted) {
      setState(() {
        filteredUsers = users;
      });
    }
  }

  listHeader(title) {
    return SliverPersistentHeader(
      pinned: true,
      floating: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 40.0,
        maxHeight: 40.0,
        child: Container(
          color: Color(0xFFF8F8F8),
          padding: EdgeInsets.only(left: 20, top: 7),
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  listBody(List<Contact> group) {
    List<Widget> listItems = List();

    for (Contact user in group) {
      dynamic component = Slidable(
        actionPane: SlidableDrawerActionPane(),
        actionExtentRatio: 0.25,
        secondaryActions: <Widget>[
          IconSlideAction(
            iconWidget: Icon(Icons.star),
            onTap: () {},
          ),
          IconSlideAction(
            iconWidget: Icon(Icons.more_horiz),
            onTap: () {},
          ),
        ],
        child: Container(
          decoration: new BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: const Color(0xFFDCDCDC)))),
          child: ListTile(
            contentPadding:
                EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
            leading: CircleAvatar(
              backgroundColor: Color(0xFFE0E0E0),
              radius: 25,
              backgroundImage: user.avatar != null && user.avatar.isNotEmpty
                  ? MemoryImage(user.avatar)
                  : new AssetImage('assets/images/anom.png'),
            ),
            title: Text(
              user.displayName,
              style: TextStyle(
                  fontSize: 15, color: Theme.of(context).primaryColor),
            ),
            //subtitle: Text("user.company" ?? ""),
            onTap: () {
              Navigator.pushNamed(context, '/SendAmount',
                  arguments: SendAmountArguments(
                      name: user.displayName,
                      // accountAddress: t,
                      avatar: user.avatar != null && user.avatar.isNotEmpty
                          ? MemoryImage(user.avatar)
                          : new AssetImage('assets/images/anom.png'),
                      phoneNumber: user.phones.first.value));
            },
          ),
        ),
      );

      listItems.add(component);
    }
    return SliverList(
      delegate: SliverChildListDelegate(listItems),
    );
  }


  Widget sendToAcccountAddress (String accountAddress) {
    Widget component = Slidable(
        actionPane: SlidableDrawerActionPane(),
        actionExtentRatio: 0.25,
        secondaryActions: <Widget>[
          IconSlideAction(
            iconWidget: Icon(Icons.star),
            onTap: () {},
          ),
          IconSlideAction(
            iconWidget: Icon(Icons.more_horiz),
            onTap: () {},
          ),
        ],
        child: Container(
          decoration: new BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: const Color(0xFFDCDCDC)))),
          child: ListTile(
            contentPadding:
                EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
            leading: CircleAvatar(
              backgroundColor: Color(0xFFE0E0E0),
              radius: 25,
              backgroundImage: new AssetImage('assets/images/anom.png'),
            ),
            title: Text(
              accountAddress,
              style: TextStyle(fontSize: 16),
            ),
            //subtitle: Text("user.company" ?? ""),
            onTap: () {
              Navigator.pushNamed(context, '/SendAmount',
                  arguments: SendAmountArguments(
                      accountAddress: accountAddress,
                      name: formatAddress(accountAddress),
                      avatar: new AssetImage('assets/images/anom.png')));
            },
          ),
        ),
      );
    return SliverList(
      delegate: SliverChildListDelegate([component]),
    );
  }

  Widget recentContacts(numToShow) {
    List<Widget> listItems = List();
    final sorted = new List<Transaction>.from(
            this.widget.viewModel.transactions.list.toSet().toList())
        .where((t) {
      return t.type == 'SEND';
    }).toList()
          ..sort((a, b) {
            if (a.blockNumber != null && b.blockNumber != null) {
              return b.blockNumber?.compareTo(a.blockNumber);
            } else {
              return b.status.compareTo(a.status);
            }
          });

    Map<String, Transaction> uniqueValues = {};
    for (var item in sorted) {
      final Contact contact = getContact(
          item,
          this.widget.viewModel.reverseContacts,
          this.widget.viewModel.contacts,
          this.widget.viewModel.countryCode);
      var a = contact != null
          ? contact.displayName
          : deducePhoneNumber(item, this.widget.viewModel.reverseContacts);
      uniqueValues[a] = item;
    }

    dynamic uniqueList = uniqueValues.values.toList().length > numToShow
        ? uniqueValues.values.toList().sublist(0, numToShow)
        : uniqueValues.values.toList();
    for (int i = 0; i < uniqueList.length; i++) {
      if (i == 0) {
        listItems.add(Container(
            padding: EdgeInsets.only(left: 15, top: 15, bottom: 8),
            child: Text(I18n.of(context).recent,
                style: TextStyle(
                    color: Color(0xFF979797),
                    fontSize: 12.0,
                    fontWeight: FontWeight.normal))));
      }
      final Transaction transaction = uniqueList[i];
      final Contact contact = getContact(
          transaction,
          this.widget.viewModel.reverseContacts,
          this.widget.viewModel.contacts,
          this.widget.viewModel.countryCode);
      listItems.add(
        Slidable(
          actionPane: SlidableDrawerActionPane(),
          actionExtentRatio: 0.25,
          secondaryActions: <Widget>[
            IconSlideAction(
              iconWidget: Icon(Icons.star),
              onTap: () {},
            ),
            IconSlideAction(
              iconWidget: Icon(Icons.more_horiz),
              onTap: () {},
            ),
          ],
          child: Container(
            decoration: new BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: const Color(0xFFDCDCDC)))),
            child: ListTile(
              contentPadding:
                  EdgeInsets.only(top: 5, bottom: 5, left: 16, right: 16),
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE0E0E0),
                radius: 25,
                backgroundImage: contact?.avatar != null
                    ? MemoryImage(contact.avatar)
                    : new AssetImage('assets/images/anom.png'),
              ),
              title: Text(
                contact != null
                    ? contact.displayName
                    : deducePhoneNumber(
                        transaction, this.widget.viewModel.reverseContacts),
                style: TextStyle(fontSize: 16),
              ),
              //subtitle: Text("user.company" ?? ""),
              onTap: () {
                Map<String, String> reverseContacts =
                    this.widget.viewModel.reverseContacts;
                String number = formatPhoneNumber(contact.phones.first.value,
                    this.widget.viewModel.countryCode);
                String accountAddress = reverseContacts.keys.firstWhere(
                    (k) => reverseContacts[k] == number,
                    orElse: () => null);
                Navigator.pushNamed(context, '/SendAmount',
                    arguments: SendAmountArguments(
                        accountAddress: accountAddress,
                        name: contact != null
                            ? contact.displayName
                            : deducePhoneNumber(transaction,
                                this.widget.viewModel.reverseContacts),
                        avatar: contact?.avatar != null
                            ? MemoryImage(contact.avatar)
                            : new AssetImage('assets/images/anom.png'),
                        phoneNumber: contact.phones.toList()[0].value));
              },
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildListDelegate(listItems),
    );
  }

  List<Widget> _buildPageList() {
    List<Widget> listItems = List();

    listItems.add(searchPanel());

    if (isPreloading) {
      return listItems;
    } 

    if (searchController.text.isEmpty) {
      listItems.add(recentContacts(3));
    } else if (isValidEthereumAddress(searchController.text)) {
      listItems.add(sendToAcccountAddress(searchController.text));
    }

    Map<String, List<Contact>> groups = new Map<String, List<Contact>>();
    for (Contact c in filteredUsers) {
      String groupName = c.displayName[0];
      if (!groups.containsKey(groupName)) {
        groups[groupName] = new List<Contact>();
      }
      groups[groupName].add(c);
    }

    List<String> titles = groups.keys.toList();
    titles.sort();
    
    for (String title in titles) {
      List<Contact> group = groups[title];
      listItems.add(listHeader(title));
      listItems.add(listBody(group));
    }
    
    // for (int index = 0; index < abList.length; index++) {
    //   listItems.add(listHeader(abList[index]));
    //   listItems.add(listBody(abList[index]));
    // }

    return listItems;
  }

  searchPanel() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 80.0,
        maxHeight: 100.0,
        child: Container(
          decoration: new BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border:
                  Border(bottom: BorderSide(color: const Color(0xFFDCDCDC)))),
          padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: FocusScope(
                    onFocusChange: (showFooter) => _onFocusChange(showFooter),
                    child: TextFormField(
                      controller: searchController,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(0.0),
                        border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFFE0E0E0), width: 3)),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: const Color(0xFF292929)),
                        ),
                        suffixIcon: Icon(
                          Icons.search,
                          color: Color(0xFFACACAC),
                        ),
                        labelText: I18n.of(context).search,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                child: new FloatingActionButton(
                    backgroundColor: const Color(0xFF292929),
                    elevation: 0,
                    child: Image.asset(
                      'assets/images/scan.png',
                      width: 25.0,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    onPressed: () async {
                      try {
                        String accountAddress = await BarcodeScanner.scan();
                        List<String> parts = accountAddress.split(':');
                        if (parts.length == 2 && parts[0] == 'fuse') {
                          Navigator.pushNamed(context, '/SendAmount',
                              arguments: SendAmountArguments(
                                  accountAddress: parts[1]));
                        } else {
                          print('Account address is not on Fuse');
                        }
                      } catch (e) {}
                    }),
                width: 50.0,
                height: 50.0,
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      withPadding: false,
      title: I18n.of(context).send_to,
      titleFontSize: 15,
      footer: showFooter ? 
      bottomBar(context) : null,
      sliverList: _buildPageList(),
      children: <Widget>[
        !this.widget.viewModel.isContactsSynced
            ? Padding(
                padding: EdgeInsets.only(top: 50),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : Container()
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    @required this.minHeight,
    @required this.maxHeight,
    @required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;
  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => math.max(maxHeight, minHeight);
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool isSync = false;

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<AppState, ContactsViewModel>(
        distinct: true,
        converter: ContactsViewModel.fromStore,
        onInit: (Store<AppState> store) async {
          bool isPermitted = await Contacts.checkPermissions();
          if (!isPermitted) {
            Future.delayed(
                Duration.zero,
                () => showDialog(
                    child: new ContactsConfirmationScreen(), context: context));
          }
          setState(() {
            isSync = isPermitted;
          });
        },
        onWillChange: (viewModel) async {
          bool isPermitted = await Contacts.checkPermissions();
          setState(() {
            isSync = isPermitted;
          });
        },
        builder: (_, viewModel) {
          // if (!isSync) {
          //   return MainScaffold(
          //       withPadding: true,
          //       titleFontSize: 15,
          //       title: I18n.of(context).send_to,
          //       children: <Widget>[
          //         Column(
          //           mainAxisSize: MainAxisSize.max,
          //           crossAxisAlignment: CrossAxisAlignment.center,
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: <Widget>[
          //             Container(
          //               padding: EdgeInsets.only(top: 180),
          //               child: SvgPicture.asset(
          //                 'assets/images/contacts.svg',
          //                 width: 50.0,
          //                 height: 50,
          //               ),
          //             ),
          //             SizedBox(
          //               height: 40,
          //             ),
          //             new Text(I18n.of(context).sync_contacts),
          //             SizedBox(
          //               height: 40,
          //             ),
          //             Row(
          //               mainAxisAlignment: MainAxisAlignment.center,
          //               crossAxisAlignment: CrossAxisAlignment.center,
          //               children: <Widget>[
          //                 new Text(I18n.of(context).learn_more),
          //                 SizedBox(
          //                   width: 20,
          //                 ),
          //                 InkWell(
          //                     child: Row(
          //                       mainAxisAlignment: MainAxisAlignment.center,
          //                       children: <Widget>[
          //                         new Text(
          //                           I18n.of(context).activate,
          //                           style: TextStyle(color: Color(0xFF0377FF)),
          //                         ),
          //                         SizedBox(
          //                           width: 5,
          //                         ),
          //                         SvgPicture.asset(
          //                             'assets/images/blue_arrow.svg')
          //                       ],
          //                     ),
          //                     onTap: () async {
          //                       bool premission =
          //                           await ContactController.getPermissions();
          //                       if (premission) {
          //                         List<Contact> contacts =
          //                             await ContactController.getContacts();
          //                         viewModel.syncContacts(contacts);
          //                       }
          //                     })
          //               ],
          //             )
          //           ],
          //         )
          //       ]);
          // } else {
          // }
            return SendToContactScreen(viewModel);
        });
  }
}
