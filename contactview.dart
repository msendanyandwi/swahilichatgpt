import 'package:http/http.dart' as http;

import 'package:timezone/timezone.dart' as tz;

import 'package:intl/intl.dart';

import 'fetchContactDetailsFunction.dart';

import '../../Exports.dart';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

enum ReminderInterval2 {
  NOW,
  THIRTY_MINUTES,
  TWO_MINUTES,
  ONE_DAY,
  EVERY_HOUR,
  EVERY_DAY,
}

class Contact {
  final String name;
  final phoneNumber;
  final jobTitle;
  final email;
  final websiteUrl;
  final address;
  final note;
  final String organization;
  final String dayOfWeek;
  final String formattedDate; // Add a new field for formatted date
  final String imageUrl;
  bool isChecked;
  final String docId;
  final String content;

  Contact(
    this.name,
    this.organization,
    this.dayOfWeek,
    this.formattedDate,
    this.phoneNumber,
    this.email,
    this.jobTitle,
    this.websiteUrl,
    this.address,
    this.note,
    this.imageUrl,
    this.isChecked,
    this.docId,
    this.content,
  );
}

class ContactsView extends StatefulWidget {
  @override
  _ContactsViewState createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  ReminderInterval2? selectedInterval;

  static Future<List<Map<String, dynamic>>> fetchContacts(String userId) async {
    List<Map<String, dynamic>> contacts =
        await ContactService.fetchContactDetails(userId);
    return contacts;
  }

  Future<String> fetchDisplayName(String uid) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userSnapshot =
        await firestore.collection('SwacardUzers').doc(uid).get();
    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      String displayName = userData['displayName'];
      return displayName;
    } else {
      return "";
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  final List<Contact> contacts = [];

  List<Contact> filteredContacts = [];

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    fetchContacts(userId).then((retrievedContacts) {
      setState(() {
        contacts.clear(); // Clear the hardcoded contacts list
        contacts.addAll(retrievedContacts.map((contactData) => Contact(
              contactData['name'],
              contactData['company'],
              contactData['dayOfWeek'], // Use the formatted day
              contactData['formattedDate'], // Use the formatted
              contactData['phoneNumber'],
              contactData['email'],
              contactData['jobTitle'],
              contactData['websiteUrl'],
              contactData['address'],
              contactData['note'],

              "https://firebasestorage.googleapis.com/v0/b/swahilicards-6cf30.appspot.com/o/userprofile.png?alt=media&token=0a6050ad-8638-499c-9598-89d4c15e5eba", // Empty imageUrl
              false,
              contactData['docId'],
              contactData['content'],
            )));
        filteredContacts = contacts.toList();
      });
    });
  }

  void _showFollowUpBottomSheet(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Set this to transparent
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8, // 80% of the height
        maxChildSize: 0.8, // 80% of the height
        builder: (BuildContext context, ScrollController scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: Material(
              color: Colors
                  .grey, // This ensures the whole content is non-transparent
              child: Stack(
                children: [
                  FollowUpAIPage(
                    name: contact.name,
                    jobTitle: contact.jobTitle,
                    companyName: contact.organization,
                    address: contact.address,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _showContactDetailsBottomSheet(
      BuildContext context, Contact contact) async {
    final textControllers = <TextEditingController>[
      TextEditingController(text: contact.name),
      TextEditingController(text: contact.phoneNumber),
      TextEditingController(text: contact.email),
      TextEditingController(text: contact.organization),
      TextEditingController(text: contact.jobTitle),
      TextEditingController(text: contact.websiteUrl),
      TextEditingController(text: contact.address),
      TextEditingController(text: contact.note),
    ];

// Custom function to create styled buttons

    Widget _styledButton({
      required String label,
      required Color backgroundColor,
      required Color textColor,
      required VoidCallback onPressed,
    }) {
      return Expanded(
        flex: 2,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: backgroundColor,
            elevation: 2, // Reduced elevation for a more subtle shadow
            shadowColor: Colors.black
                .withOpacity(0.2), // Lighter shadow for a more subtle effect
            minimumSize: const Size(double.infinity, 45), // Reduced height
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  25), // Increased border radius for a more rounded look
            ),
            textStyle: const TextStyle(
              fontSize: 16, // Reduced font size
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      );
    }

    const double buttonSpacing = 10.0; // Adjust the spacing here

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 70, 70, 70),
                    Color.fromARGB(255, 32, 32, 32)
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Contact Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            Navigator.pop(
                                context); // This will close the bottom sheet
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Generate TextFormFields using a loop with SizedBox in between
                    for (int i = 0; i < textControllers.length; i++) ...[
                      _buildTextField(
                        controller: textControllers[i],
                        labelText: _getLabelText(i),
                      ),
                      SizedBox(height: 8), // Added SizedBox
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _styledButton(
                          label: 'Edit',
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          onPressed: () {
                            _updateContact(contact, textControllers);
                            Navigator.pop(context);
                          },
                        ),
                        SizedBox(width: buttonSpacing), // Add spacing here
                        _styledButton(
                          label: 'Delete',
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          onPressed: () async {
                            await deleteUserContact(contact.docId);

                            // ignore: use_build_context_synchronously
                            Navigator.pop(
                                context); // Close the bottom sheet after deletion
                          },
                        ),
                        const SizedBox(
                            width: buttonSpacing), // Add spacing here

                        IconButton(
                          icon: const Icon(
                            Icons.save_alt_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () async {
                            String contentUrl =
                                contact.content; // Get the website URL

                            // Check if the website URL is not empty or 'N/A'
                            if (contentUrl != null && contentUrl != 'N/A') {
                              // Attempt to launch the URL in the browser
                              if (await canLaunch(contentUrl)) {
                                await launch(contentUrl);
                              } else {
                                Fluttertoast.showToast(
                                    msg: "Could not launch URL");
                              }
                            } else {
                              Fluttertoast.showToast(
                                  msg: "Website URL not available");
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? labelText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white, // Assuming a dark theme similar to Spotify
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey,
          ),
          contentPadding:
              EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.5), // Subtle border color
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey
                  .withOpacity(0.5), // Maintain the subtle border when focused
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  String _getLabelText(int index) {
    switch (index) {
      case 0:
        return 'Full name';
      case 1:
        return 'Phone number';
      case 2:
        return 'Email';
      case 3:
        return 'Company';
      case 4:
        return 'Job Title';
      case 5:
        return 'Website Url';
      case 6:
        return 'Address';
      case 7:
        return 'Note';
      default:
        return '';
    }
  }

  Future<void> deleteUserContact(String docId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('UserContacts')
          .doc(docId)
          .delete();
    } catch (e) {}
  }

  void _updateContact(
      Contact contact, List<TextEditingController> controllers) async {
    try {
      // Build the updated contact
      Contact updatedContact = Contact(
        controllers[0].text.isEmpty ? contact.name : controllers[0].text,
        controllers[3].text.isEmpty
            ? contact.organization
            : controllers[3].text,
        contact.dayOfWeek,
        contact.formattedDate,
        controllers[1].text.isEmpty ? contact.phoneNumber : controllers[1].text,
        controllers[2].text.isEmpty ? contact.email : controllers[2].text,
        controllers[4].text.isEmpty ? contact.jobTitle : controllers[4].text,
        controllers[5].text.isEmpty ? contact.websiteUrl : controllers[5].text,
        controllers[6].text.isEmpty ? contact.address : controllers[6].text,
        controllers[7].text.isEmpty ? contact.note : controllers[7].text,
        contact.imageUrl,
        contact.isChecked,
        contact.docId,
        contact.content,
      );

      // Attempt to update Firestore
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance
          .collection('UserContacts')
          .doc(contact.docId); // Assuming docId is the document ID in Firestore

      await docRef.update({
        'contactInfo': {
          'fullName': updatedContact.name,
          'company': updatedContact.organization,
          'phoneNumber': updatedContact.phoneNumber,
          'email': updatedContact.email,
          'jobTitle': updatedContact.jobTitle,
          'websiteUrl': updatedContact.websiteUrl,
          'address': updatedContact.address,
          'note': updatedContact.note,
          'content': updatedContact.content,
        },
      }).then((_) {
        // Update the local state
        setState(() {
          // Find the index of the updated contact in the contacts list
          int index = contacts.indexWhere((c) => c.docId == contact.docId);

          if (index != -1) {
            // Replace the old contact with the updated one in the contacts list
            contacts[index] = updatedContact;
          } else {}
        });

        // Show a success toast
        Fluttertoast.showToast(
          msg: 'Contact updated successfully!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }).catchError((error) {});
    } catch (e) {}
  }

  void showSuccessToast() {
    Fluttertoast.showToast(
      msg: 'Contact updated successfully!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  void showErrorToast(error) {
    Fluttertoast.showToast(
      msg: 'Error updating Firestore document: $error',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Export as CSV to any CRM'),
                  onTap: () async {
                    Navigator.pop(context); // Close the bottom sheet

                    String downloadURL = await exportContacts();
                    Uri downloadUri = Uri.parse(downloadURL);

                    if (await launchUrl(downloadUri)) {
                      await canLaunchUrl(downloadUri);
                    } else {
                      throw 'Could not launch $downloadURL';
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.cloud_upload),
                  title: Text('Connect to Zapier, Access 5000+ CRM'),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    // Show a toast message indicating the feature is coming soon
                    Fluttertoast.showToast(
                      msg: 'This feature is coming soon!',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.grey,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  },
                ),
              ],
            ),
          );
        });
  }

  Future<String> exportContacts() async {
    List<List<dynamic>> rows = []; // updated line
    rows.add([
      "CONTACT NAME",
      "COMPANY",
      "PHONE NUMBER",
      "EMAIL",
      "JOB TITLE",
      "WEBSITE",
      "ADDRESS",
      "NOTE"
    ]); // headers
    for (Contact contact in contacts) {
      List<dynamic> row = []; // updated line
      row.add(contact.name);
      row.add(contact.organization);
      row.add(contact.phoneNumber);
      row.add(contact.email);
      row.add(contact.jobTitle);
      row.add(contact.websiteUrl);
      row.add(contact.address);
      row.add(contact.note);
      rows.add(row);
    }
    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/contacts.csv');
    await file.writeAsString(csv);

    // Upload the file to Firebase Cloud Storage
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('contacts.csv');
    UploadTask uploadTask = ref.putFile(file);

    // Wait for the upload to complete
    await uploadTask;

    // Get the download URL
    String downloadURL = await ref.getDownloadURL();

    return downloadURL;
  }

  void filterContacts(String query) {
    setState(() {
      if (query.isNotEmpty) {
        filteredContacts = contacts.where((contact) {
          final nameLower = contact.name.toLowerCase();
          final orgLower = contact.organization.toLowerCase();
          return nameLower.contains(query.toLowerCase()) ||
              orgLower.contains(query.toLowerCase());
        }).toList();
      } else {
        filteredContacts =
            contacts.toList(); // Show all contacts when the query is empty
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 2,
          title: const Text(
            "My Connections",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    _showExportOptions(context);
                  },
                  icon: SvgPicture.asset(
                    'assets/homeicons/export.svg',
                    color: const Color.fromRGBO(255, 255, 255, 1),
                    width: 30,
                    height: 30,
                  ),
                )
              ],
            ),
          ],
        ),
        body: Container(
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
          child: Column(
            children: [
              buildSearchBar(
                  filterContacts), // Updated: Pass filterContacts to the search bar
              const SizedBox(
                  height: 10), // Add some space between search bar and the list
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchContacts(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CustomCircularLoader());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('An error occurred!'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text(
                        'No contacts found!\nMake Connections',
                        style: TextStyle(color: Colors.white),
                      ));
                    } else {
                      return ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              buildContactRow(contacts[index]),
                              const Divider(
                                color: Colors.grey,
                              ), // Adds a horizontal line after each row
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar(Function(String) filterFunction) {
    // Updated: Pass filterFunction to the search bar
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => filterFunction(
                          value), // Update the filter with user input
                      decoration: const InputDecoration(
                        hintText: 'Search names, Companies here',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              // Perform navigation or action when the plus icon is tapped

              Navigator.pushNamed(context, '/contactsadd');
            },
            child: Icon(Icons.add_circle, size: 50, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget buildContactRow(Contact contact) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              // Toggle the checked status of the contact
              setState(() {
                contact.isChecked = !contact.isChecked;
              });
            },
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: contact.isChecked ? Colors.transparent : Colors.green,
              ),
              child: contact.isChecked
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
              image: DecorationImage(
                image: NetworkImage(contact.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  contact.organization,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${contact.dayOfWeek}, ${contact.formattedDate}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Row(
            // Changed from Column to Row
            children: [
              GestureDetector(
                onTap: () async {
                  // showReminderBottomSheet(context, contact.name);
                  // Now, this will generate a reminder based on the contact's details.
                  _showFollowUpBottomSheet(context, contact);
                },
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Row(
            // Changed from Column to Row
            children: [
              GestureDetector(
                onTap: () async {
                  // await _showContactDetailsBottomSheet(context, contact);
                  _showOptionsBottomSheet(context, contact);
                },
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, Contact contact) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Contact'),
              onTap: () async {
                Navigator.pop(context);
                // Call your _showContactDetailsBottomSheet function here
                await _showContactDetailsBottomSheet(context, contact);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Send via WhatsApp'),
              onTap: () async {
                Navigator.pop(context);

                FirebaseAuth auth = FirebaseAuth.instance;
                User? user = auth.currentUser;

                if (user != null) {
                  String uid = user.uid; // Get the UID from FirebaseAuth

                  String displayName = await fetchDisplayName(uid);

                  String message =
                      "Hello ${contact.name},\n\n I wanted to express my gratitude for our recent meeting. It was a pleasure connecting with you.\n\n Its $displayName here! we met at ${contact.address}";

                  String url =
                      "https://wa.me/${contact.phoneNumber}?text=${Uri.encodeComponent(message)}";

                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    // Handle the error or show a message to the user
                  }
                } else {
                  // Handle the case where the user is not authenticated
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.sms),
              title: const Text('Send Sms'),
              onTap: () async {
                Navigator.pop(context);

                FirebaseAuth auth = FirebaseAuth.instance;
                User? user = auth.currentUser;

                String uid = user!.uid; // Get the UID from FirebaseAuth

                String displayName = await fetchDisplayName(uid);
                final Uri emailLaunchUri = Uri(
                  scheme: 'sms',
                  path: contact.email,
                  queryParameters: {
                    'subject': '',
                    'body':
                        'Hello ${contact.name}, \n\n I wanted to express my gratitude for our recent meeting. It was a pleasure connecting with you.\n\nIts $displayName here! we met at ${contact.address}',
                  },
                );

                if (await launchUrl(emailLaunchUri)) {
                  await canLaunchUrl(emailLaunchUri);
                } else {}
              },
            ),
            ListTile(
              leading: const Icon(Icons.call),
              title: const Text('Make a Call'),
              onTap: () async {
                Navigator.pop(context);
                String url = "tel:${contact.phoneNumber}";
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  // Handle the error or show a message to the user
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send Email'),
              onTap: () async {
                Navigator.pop(context);

                FirebaseAuth auth = FirebaseAuth.instance;
                User? user = auth.currentUser;

                String uid = user!.uid; // Get the UID from FirebaseAuth

                String displayName = await fetchDisplayName(uid);
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: contact.email,
                  query: encodeQueryParameters(<String, String>{
                    'subject': 'Nice Meeting You!',
                    'body':
                        'Dear ${contact.name},\n\n I wanted to express my gratitude for our recent meeting. It was a pleasure connecting with you.\n\nWe met at ${contact.address}\n\n Yours Faithfully \n\n $displayName! ',
                  }),
                );

                if (await launchUrl(emailLaunchUri)) {
                  await canLaunchUrl(emailLaunchUri);
                } else {}
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_page),
              title: const Text('Save Contact'),
              onTap: () async {
                Navigator.pop(context);
                final String url = contact.content;

                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  // Handle the situation when the URL can't be opened
                }
              },
            ),
          ],
        );
      },
    );
  }
}
