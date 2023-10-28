import '../Exports.dart';

class VirtualWalletContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Analytics Content',
        style: TextStyle(color: Colors.orange),
      ),
    );
  }
}

class UserDashboardScreen extends StatefulWidget {
  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  bool isSwahiliCardSelected = true;

  User? user;

  String formatNumber(int num) {
    if (num >= 1000000) {
      double roundedValue = (num / 1000000 * 10).round() / 10;
      return "${roundedValue.toStringAsFixed(1)}M";
    }
    if (num >= 1000) {
      double roundedValue = (num / 1000 * 10).round() / 10;
      return "${roundedValue.toStringAsFixed(1)}K";
    }
    return num.toString();
  }

  Future<String> fetchCardViews(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      DocumentSnapshot userSnapshot =
          await firestore.collection('SwacardUzers').doc(userId).get();
      int cardViews = userSnapshot['cardViews'] ?? 0;
      return formatNumber(cardViews); // Use the formatNumber function here
    } catch (e) {
      print(e);
      return '0'; // handle the error appropriately
    }
  }

  Future<List<int>> fetchAllUserViews() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot userSnapshots =
          await firestore.collection('SwacardUzers').get();
      List<int> allViews = userSnapshots.docs.map((doc) {
        return doc['cardViews'] as int ?? 0;
      }).toList();
      return allViews;
    } catch (e) {
      print(e);
      return []; // handle the error appropriately
    }
  }

  Future<String> getUserRank(String userId) async {
    try {
      // Fetch user views as integer directly
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('SwacardUzers')
          .doc(userId)
          .get();
      int userViews = userSnapshot['cardViews'] ?? 0;

      List<int> allUserViews = await fetchAllUserViews();
      List<int> sortedViews = List.from(allUserViews)
        ..sort((a, b) => b.compareTo(a)); // Sort in descending order

      int rank = 1;
      int prevViews = -1;

      for (int i = 0; i < sortedViews.length; i++) {
        if (sortedViews[i] != prevViews) {
          rank = i + 1;
          prevViews = sortedViews[i];
        }

        if (sortedViews[i] == userViews) {
          return rank
              .toString(); // Return rank as soon as user's views are found
        }
      }

      // If user's views are not found (which means they have 0 views), and there are other users with 0 views
      if (userViews == 0 && sortedViews.contains(0)) {
        int zeroViewRank = sortedViews.indexOf(0) + 1;
        return zeroViewRank.toString();
      }

      // If no users have 0 views, or user's views are not found for some other reason
      return (rank + 1).toString(); // Assign next rank
    } catch (error) {
      print('Error fetching user rank: $error');
      return 'NA';
    }
  }

  Future<Map<String, dynamic>> fetchUserDetails(String uid) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userSnapshot =
        await firestore.collection('SwacardUzers').doc(uid).get();
    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      if (userData['photoURL'] == null || userData['photoURL'].isEmpty) {
        await firestore.collection('SwacardUzers').doc(uid).update({
          'photoURL':
              'https://firebasestorage.googleapis.com/v0/b/swahilicards-6cf30.appspot.com/o/userprofile.png?alt=media&token=0a6050ad-8638-499c-9598-89d4c15e5eba'
        });
        userData['photoURL'] =
            'https://firebasestorage.googleapis.com/v0/b/swahilicards-6cf30.appspot.com/o/userprofile.png?alt=media&token=0a6050ad-8638-499c-9598-89d4c15e5eba';
      }
      return userData;
    } else {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserContacts(String userId) async {
    QuerySnapshot userCardDetailsSnapshot = await FirebaseFirestore.instance
        .collection('UserContacts')
        .where('uid', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    List<Map<String, dynamic>> UserContactsList = [];

    for (QueryDocumentSnapshot userCardSnapshot
        in userCardDetailsSnapshot.docs) {
      var userCardData = userCardSnapshot.data() as Map<String, dynamic>;
      if (userCardData.containsKey('contactInfo')) {
        var contactInfo = userCardData['contactInfo'];
        UserContactsList.add(contactInfo);
      }
    }

    return UserContactsList;
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 18) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If the user is not authenticated, navigate to the authentication page
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushReplacementNamed(
            '/authscreen'); // Replace with your authentication route name
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String greeting = getGreeting();

    if (user == null) {
      // Return a loading indicator or an empty container while waiting to navigate
      return CustomCircularLoader(); // Replace with your loading widget
    }

    String? uid =
        user?.uid; // Add a null check using the null-aware operator (?.)

    if (uid != null) {
      // Now, you can safely use uid without worrying about null values
      print("User UID: $uid");
    }

    String? userId = user?.uid;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        // Adding gradient background similar to Spotify's
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF373737)
            ], // Gradient colors similar to Spotify's theme
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FutureBuilder<Map<String, dynamic>>(
                    future: fetchUserDetails(uid!),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else if (!snapshot.hasData) {
                        return Container(); // Show a loading indicator or another widget if you prefer
                      } else {
                        Map<String, dynamic> userData = snapshot.data!;
                        String companyName = userData['companyName'];
                        String jobTitle = userData['jobTitle'];
                        String displayName = userData['displayName'] ?? '';
                        String photoURL = userData['photoURL'];

                        return Column(
                          children: [
                            const SizedBox(height: 30),
                            Center(
                              child: Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "SwahiliCard",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 25,
                                          ),
                                        ),
                                        SizedBox(height: 4.0),
                                        Text(
                                          "Every connection matters",
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          builder: (context) => SafeArea(
                                              child: ShareCardBottomSheet()),
                                        );
                                      },
                                      icon: SvgPicture.asset(
                                        'assets/homeicons/share.svg',
                                        color: Colors.white60,
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomContainer(
                                          isSelected: isSwahiliCardSelected,
                                          text: 'Professional Hub',
                                          onTap: () {
                                            setState(() {
                                              isSwahiliCardSelected = true;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: CustomContainer(
                                          isSelected: !isSwahiliCardSelected,
                                          text: 'Analytics',
                                          onTap: () {
                                            setState(() {
                                              isSwahiliCardSelected = false;
                                              VirtualWalletContent();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting)
                                    CustomCircularLoader(),
                                  if (snapshot.hasError)
                                    Text("Error: ${snapshot.error}"),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            isSwahiliCardSelected
                                ? Column(
                                    children: [
                                      MyCardWidget(
                                        photoURL: photoURL,
                                        greeting: greeting,
                                        displayName: displayName,
                                        jobTitle: jobTitle,
                                        companyName: companyName,
                                        screenWidth: screenWidth,
                                        screenHeight: screenHeight,
                                        onTapEdit: () {
                                          Navigator.pushNamed(
                                              context, '/addcontentUseredit');
                                        },
                                        context: context,
                                      ),
                                      const SizedBox(height: 30),
                                      FractionallySizedBox(
                                        widthFactor: 0.9,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Overview',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                            SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Card(
                                                    color: Colors.white70,
                                                    elevation: 5.0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        ListTile(
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 16.0,
                                                            vertical: 10.0,
                                                          ),
                                                          leading: const Icon(
                                                              Icons.map,
                                                              size: 36,
                                                              color: Colors
                                                                  .blueGrey),
                                                          title: FutureBuilder<
                                                              String>(
                                                            future: getUserRank(
                                                                userId!),
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .waiting) {
                                                                return SizedBox(
                                                                  width: 30.0,
                                                                  height: 30.0,
                                                                  child: Center(
                                                                      child:
                                                                          CustomCircularLoader()),
                                                                );
                                                              }
                                                              if (snapshot
                                                                  .hasError) {
                                                                return Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      'Error loading ranking.',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .red,
                                                                          fontSize:
                                                                              16),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            5),
                                                                    Text(
                                                                      'Tap to retry',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blue,
                                                                          fontSize:
                                                                              14),
                                                                    ),
                                                                  ],
                                                                );
                                                              }
                                                              return Text(
                                                                '#${snapshot.data}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              );
                                                            },
                                                          ),
                                                          subtitle: const Text(
                                                            'Ranking',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .blueGrey),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Card(
                                                    color: Colors.white70,
                                                    elevation: 5.0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        ListTile(
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 16.0,
                                                            vertical: 10.0,
                                                          ),
                                                          leading: const Icon(
                                                            Icons
                                                                .auto_graph_outlined,
                                                            size: 36,
                                                            color:
                                                                Colors.blueGrey,
                                                          ),
                                                          title: FutureBuilder<
                                                              String>(
                                                            future:
                                                                fetchCardViews(
                                                                    userId!),
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .waiting) {
                                                                return SizedBox(
                                                                  width: 30.0,
                                                                  height: 30.0,
                                                                  child: Center(
                                                                      child:
                                                                          CustomCircularLoader()),
                                                                );
                                                              }
                                                              if (snapshot
                                                                  .hasError) {
                                                                return const Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      'Error loading card views.',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .red,
                                                                          fontSize:
                                                                              16),
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            5),
                                                                    Text(
                                                                      'Tap to retry',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .blue,
                                                                          fontSize:
                                                                              14),
                                                                    ),
                                                                  ],
                                                                );
                                                              }
                                                              return Text(
                                                                '${snapshot.data}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              );
                                                            },
                                                          ),
                                                          subtitle: const Text(
                                                            'Card Views',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .blueGrey),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      FractionallySizedBox(
                                        widthFactor: 0.9,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'New Connections',
                                                  style: TextStyle(
                                                    color: Color(0xFFFFFFFF),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  'Make Follow-ups',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),
                                            FutureBuilder<
                                                List<Map<String, dynamic>>>(
                                              future: fetchUserContacts(uid),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return CustomCircularLoader();
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      "Error: ${snapshot.error}");
                                                } else {
                                                  List<Map<String, dynamic>>
                                                      userContacts =
                                                      snapshot.data!;
                                                  if (userContacts.isEmpty) {
                                                    return const Text(
                                                      "You've no connection.",
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFFFFFFFF),
                                                      ),
                                                    );
                                                  }
                                                  return Container(
                                                    width: 0.9 * screenWidth,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 10),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Color(0xFF373737),
                                                          Color(0xFF121212),
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                  0.15),
                                                          blurRadius: 8,
                                                          offset: Offset(0, 5),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      children: userContacts
                                                          .map<Widget>(
                                                              (contactInfo) {
                                                        String fullName =
                                                            contactInfo[
                                                                'fullName'];
                                                        String companyName =
                                                            contactInfo[
                                                                'company'];
                                                        String
                                                            companyNameWithoutRetrieve =
                                                            companyName;
                                                        return Column(
                                                          children: [
                                                            TransactionItem(
                                                              fullName,
                                                              'From $companyNameWithoutRetrieve',
                                                              title: fullName,
                                                              subtitle:
                                                                  'From $companyNameWithoutRetrieve',
                                                            ),
                                                            SizedBox(
                                                                height:
                                                                    screenWidth *
                                                                        0.001),
                                                            SizedBox(
                                                                height:
                                                                    screenWidth *
                                                                        0.001),
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : VirtualWalletContent(),
                          ],
                        );
                      }
                    },
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
