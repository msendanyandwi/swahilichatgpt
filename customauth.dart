import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../Exports.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class ApiCredentials {
  final String apiKey;
  final String secretKey;

  ApiCredentials(this.apiKey, this.secretKey);

  String get base64EncodedCredentials {
    final credentials = "$apiKey:$secretKey";
    return base64.encode(utf8.encode(credentials));
  }
}

class Countdown extends StatefulWidget {
  final Duration duration;

  Countdown({required this.duration});

  @override
  _CountdownState createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late Duration _time;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _time = widget.duration;

    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (_time.inSeconds > 0) {
          _time = Duration(seconds: _time.inSeconds - 1);
        } else {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int minutes = _time.inMinutes.remainder(60);
    int seconds = _time.inSeconds.remainder(60);

    return Text(
      '$minutes:$seconds',
      style: TextStyle(color: Colors.white60),
    );
  }
}

class PhoneNumberAuthenticationScreen extends StatefulWidget {
  @override
  State<PhoneNumberAuthenticationScreen> createState() =>
      _PhoneNumberAuthenticationScreenState();
}

class _PhoneNumberAuthenticationScreenState
    extends State<PhoneNumberAuthenticationScreen> {
  PreferencesHelper _preferencesHelper = PreferencesHelper();

  Future<void> _signInWithTwitter() async {
    try {
      TwitterAuthProvider twitterProvider = TwitterAuthProvider();
      UserCredential userCredential;

      if (kIsWeb) {
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(twitterProvider);
      } else {
        userCredential =
            await FirebaseAuth.instance.signInWithProvider(twitterProvider);
      }

      // Once signed in, retrieve the UserCredential
      User? user = userCredential.user;

      if (user != null) {
        // Now, you can access the user's email, display name, and photo URL
        String? email = user.email;
        String? displayName = user.displayName;
        String? photoURL = user.photoURL;

        // Generate the userURL with the firebase authenticated userID
        String userURL = "https://me.swahilicard.com/${user.uid}";

        // Check if the user's data already exists in Firestore
        DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
            .collection("SwacardUzers")
            .doc(user.uid)
            .get();
        Map<String, dynamic>? existingUserData =
            userDataSnapshot.data() as Map<String, dynamic>?;

        if (existingUserData == null) {
          // Save the user details into the Firestore collection "SwacardUzers" only if the data doesn't exist
          await FirebaseFirestore.instance
              .collection("SwacardUzers")
              .doc(user.uid)
              .set({
            "email": email,
            "displayName": displayName,
            "photoURL": photoURL,
            "userURL": userURL, // Add the userURL to the document
            "role": "user",
            "cardViews": 0,
            "cardShares": 0,
            // Add any other fields you might want to save here
          });

          // Note: The line below assumes that the method `CreateUserStep1.retrieveOrPostDisplayName` is defined and valid
          // ignore: use_build_context_synchronously
          CreateUserStep1.retrieveOrPostDisplayName(context);

          Fluttertoast.showToast(msg: "You have created an account!");

          // Navigate to UserStep1 after successful authentication if data didn't exist
          Navigator.pushReplacementNamed(context, '/userstep1');
        } else {
          // If the user's data already exists, you can choose to do something else or just move to the next screen
          // CreateUserStep1.retrieveOrPostDisplayName(context);
          Fluttertoast.showToast(
              msg: "Welcome back, ${existingUserData['displayName']}!");

          // Navigate to HomeScreen after successful authentication if data already exists
          // ignore: use_build_context_synchronously
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        Fluttertoast.showToast(msg: "User is null. Authentication failed.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
      print('Error: $e');
    }
  }

  String _generateRandomId(String uid) {
    const _chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final _random = Random();
    String randomPart = String.fromCharCodes(Iterable.generate(
        20, (_) => _chars.codeUnitAt(_random.nextInt(_chars.length))));
    return '$uid-$randomPart';
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // Initialize GoogleSignIn
      GoogleSignIn googleSignIn = GoogleSignIn();

      // Get the current signed-in account or show the account picker
      GoogleSignInAccount? googleUser = googleSignIn.currentUser;
      googleUser ??= await googleSignIn.signIn();

      if (googleUser == null) return;

      // Get the authentication credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase using the Google credentials
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(googleCredential);
      User? user = userCredential.user;

      if (user == null) return;

      // Now, you can access the user's email, display name, and photo URL
      String? email = user.email;
      String? displayName = user.displayName;
      String? photoURL = user.photoURL;
      // Generate a random ID for the QR code
      String qrCodeId = _generateRandomId(user.uid);

      // Generate the userURL with the firebaseauthenticateduserID
      String userURL = "https://me.swahilicard.com/${user.uid}";

      // Check if the user's data already exists in Firestore
      DocumentSnapshot userDataSnapshot = await FirebaseFirestore.instance
          .collection("SwacardUzers")
          .doc(user.uid)
          .get();
      Map<String, dynamic>? existingUserData =
          userDataSnapshot.data() as Map<String, dynamic>?;

      if (existingUserData == null) {
        // Save the user details into the Firestore collection "SwacardUzers" only if the data doesn't exist
        await FirebaseFirestore.instance
            .collection("SwacardUzers")
            .doc(user.uid)
            .set({
          "email": email,
          "displayName": displayName,
          "photoURL": photoURL,
          "userURL": userURL, // Add the userURL to the document
          "qrCodeId": qrCodeId,
          "role": "user",
          "cardViews": 0,
          "cardShares": 0,
          // Add any other fields you might want to save here
        });

        // ignore: use_build_context_synchronously
        CreateUserStep1.retrieveOrPostDisplayName(context);

        Fluttertoast.showToast(msg: "You have created Account!");

        // Navigate to UserStep1 after successful authentication if data didn't exist
        Navigator.pushReplacementNamed(context, '/userstep1');
      } else {
        // If the user's data already exists, you can choose to do something else or just move to the next screen
        // CreateUserStep1.retrieveOrPostDisplayName(context);
        Fluttertoast.showToast(
            msg: "Welcome back, ${existingUserData['displayName']}!");

        // Navigate to HomeScreen after successful authentication if data already exists
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
      print('errrorr: $e');
    }
  }

  bool isPasswordStrong(String password) {
    if (password.length < 8) return false; // Length Check
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(password))
      return false; // Uppercase Letter
    if (!RegExp(r'(?=.*[a-z])').hasMatch(password))
      return false; // Lowercase Letter
    if (!RegExp(r'(?=.*\d)').hasMatch(password)) return false; // Number
    if (!RegExp(r'(?=.*[@$!%*?&#])').hasMatch(password))
      return false; // Special Character

    return true;
  }

  void verifyOtpBottomsheet(
      BuildContext context, String pinId, String firebaseFormattedNumber) {
    final TextEditingController _otpController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // For fullscreen modal
      backgroundColor: Colors.black, // Dark background similar to Spotify
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 30.0),

                // Close icon
                Align(
                  alignment: Alignment.topLeft,
                  child: CircleAvatar(
                    backgroundColor: Colors.black,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Enter the OTP sent to your number',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: _otpController,
                  style: TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade800,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    labelText: 'OTP',
                    labelStyle: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 20.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: Countdown(duration: Duration(minutes: 1)),
                ),

                const SizedBox(height: 20.0),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.green, // Spotify color
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Verify'),
                    onPressed: () async {
                      String otp = _otpController.text.trim();
                      if (otp.isEmpty) {
                        Fluttertoast.showToast(msg: "Please enter OTP");
                        return;
                      }
                      String email = _emailController.text.trim();
                      String password = _passwordController.text.trim();
                      try {
                        await verifyOTP(
                            otp, pinId!); // Assuming pinId is defined elsewhere
                        Fluttertoast.showToast(
                            msg: "Phone number verified successfully!");
                        // ignore: unused_local_variable
                        UserCredential userCredential =
                            await _auth.createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        // Handle the userCredential or continue your logic here.
                      } catch (e) {
                        // Handle the error here
                        Fluttertoast.showToast(msg: e.toString());
                      }

                      await _auth.currentUser?.reload();
                      var user = _auth.currentUser;

                      String? displayName = user?.displayName;

                      // Generate the userURL with the firebase authenticated user ID
                      String userURL =
                          "https://me.swahilicard.com/${user?.uid}";

                      // Check if the user's data already exists in Firestore
                      DocumentSnapshot userDataSnapshot =
                          await FirebaseFirestore.instance
                              .collection("SwacardUzers")
                              .doc(user?.uid)
                              .get();
                      Map<String, dynamic>? existingUserData =
                          userDataSnapshot.data() as Map<String, dynamic>?;

                      if (existingUserData == null) {
                        // Save the user details into the Firestore collection "SwacardUzers" only if the data doesn't exist
                        await FirebaseFirestore.instance
                            .collection("SwacardUzers")
                            .doc(user?.uid)
                            .set({
                          "email": email,
                          "displayName": displayName,
                          "phonenumber":
                              firebaseFormattedNumber, // Updated to use the phoneNumber parameter
                          "userURL": userURL,
                          "photoURL":
                              "https://firebasestorage.googleapis.com/v0/b/swahilicards-6cf30.appspot.com/o/userprofile.png?alt=media&token=0a6050ad-8638-499c-9598-89d4c15e5eba",
                          "role": "user",
                          "cardViews": 0,
                          "cardShares": 0,
                          // Add any other fields you might want to save here
                        });
                      }

                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacementNamed(
                          context, '/userstep1Email');
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSignInBottomSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    labelStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.email, color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1ED760)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true, // This line hides the password text
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.lock, color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF1ED760)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    try {
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .signInWithEmailAndPassword(
                              email: email, password: password);

                      Navigator.pop(context); // Close the modal sheet
                      Navigator.pushReplacementNamed(context, '/home');
                      // Signed in
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'user-not-found') {
                        Fluttertoast.showToast(msg: "No user found");
                      } else if (e.code == 'Wrong email or password') {
                        Fluttertoast.showToast(msg: "Wrong email or password");
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    primary: const Color(0xFF1ED760),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  child: const Text("Sign In"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    String email = _emailController.text.trim();
                    if (email.isNotEmpty) {
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: email);
                      Fluttertoast.showToast(msg: "Password reset email sent.");
                    } else {
                      Fluttertoast.showToast(msg: "Enter your email address.");
                    }
                  },
                  child: const Center(
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Step 1: Create a method for showing bottom sheet

  void _showPhoneNumberBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Keep the background transparent
      isScrollControlled:
          true, // This helps in resizing the modal sheet when the keyboard opens
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black, // Milky white background
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  20.0, // Adjusts the bottom padding to the height of the keyboard
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // set the main axis to minimum
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Close the modal sheet
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                        10) // Since +255 is already there, allow 9 more characters
                  ],
                  style: const TextStyle(color: Colors.grey),
                  decoration: const InputDecoration(
                    prefix: Text(
                      "+255 ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    labelText: "Phone Number",
                    labelStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.phone, color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF1ED760)), // Spotify green
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    labelStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.email, color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF1ED760)), // Spotify green
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true, // This line hides the password text
                        style: TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.lock, color: Colors.white54),
                          hintText: "XXXXXXXX",
                          hintStyle: TextStyle(color: Colors.white),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFF1ED760)), // Spotify green
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _confirmPasswordController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Confirm Password",
                          labelStyle: TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.lock, color: Colors.white54),
                          hintText: "XXXXXXXX",
                          hintStyle: TextStyle(color: Colors.white),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFF1ED760)), // Spotify green
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    // Get the password from the text controller.
                    String password = _passwordController.text.trim();
                    String email = _emailController.text.trim();

                    // Check if the user already exists with the same email.
                    QuerySnapshot existingUsers = await FirebaseFirestore
                        .instance
                        .collection("SwacardUzers")
                        .where("email", isEqualTo: email)
                        .get();

                    if (existingUsers.docs.isNotEmpty) {
                      Fluttertoast.showToast(msg: "User already exists");
                      return;
                    }

                    // Check the strength of the password.
                    if (!isPasswordStrong(password)) {
                      Fluttertoast.showToast(
                          msg: "Password is not strong enough");
                      return; // Return early if the password is not strong enough.
                    }
                    await _preferencesHelper.setCompletedSteps(true);
                    _verifyPhoneNumber();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: const Color(0xFF1ED760), // Spotify green
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ApiCredentials credentials = ApiCredentials(
    "746aec3a525bc1c8",
    "YjdlYzBjOTBlYjZjZWJmZjY5OGNmNzI1ZDE0ZmY4YTQ4ZmZkMzMyYTkxMWM1MjhjYjg4MTFhMWE5MDMzODliOA==",
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> sendOTP(String phoneNumber) async {
    const url = 'https://apiotp.beem.africa/v1/request';

    final headers = {
      'Authorization': 'Basic ${credentials.base64EncodedCredentials}',
      'Content-Type': 'application/json',
    };

    final data = {
      'appId': '1337', // Replace with your app ID
      'msisdn': phoneNumber,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );

    print('API Response: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['data']
          ['pinId']; // Assuming pinId is the request_id you need to store
    } else {
      return null;
    }
  }

  String?
      pinId; // Add this at the class level to store pinId globally in the class

  Future<void> _verifyPhoneNumber() async {
    String basePhoneNumber = _phoneNumberController.text?.trim() ?? '';

    // Remove the leading zero if it exists
    if (basePhoneNumber.startsWith('0')) {
      basePhoneNumber = basePhoneNumber.substring(1);
    }
    String firebaseFormattedNumber = '+255$basePhoneNumber';
    String beemFormattedNumber = '255$basePhoneNumber';

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String verifyPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || verifyPassword.isEmpty) {
      Fluttertoast.showToast(msg: "All fields are required");
      return;
    }

    if (password != verifyPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    try {
      pinId = await sendOTP(beemFormattedNumber); // Beem formatted number

      if (pinId != null) {
        // Log the pinId value for verification
        print('pinId assigned in _verifyPhoneNumber: $pinId');

        // Show the OTP popup with Firebase formatted number
        // Navigatetoanotherscreen(context, pinId!, firebaseFormattedNumber);
        // ignore: use_build_context_synchronously
        verifyOtpBottomsheet(context, pinId!, firebaseFormattedNumber);
      } else {
        Fluttertoast.showToast(msg: "Error sending OTP");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
      print(firebaseFormattedNumber);
    }
  }

  Future<void> verifyOTP(String otp, String pinId) async {
    const url = 'https://apiotp.beem.africa/v1/verify';

    final headers = {
      'Authorization': 'Basic ${credentials.base64EncodedCredentials}',
      'Content-Type': 'application/json',
    };

    final data = {
      'pin': otp, // This is where you send the OTP entered by the user
      'pinId':
          pinId, // This is where you send the pinId saved from the sendOTP method
    };

    // Log the pinId and OTP values before making the HTTP request
    print('pinId in verifyOTP: $pinId');
    print('OTP in verifyOTP: $otp');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );

    print('OTP Verification Response: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['data']['message']['code'] == 117) {
        print('OTP verified successfully!');
        return;
      } else {
        throw Exception(
            'OTP verification failed with code: ${responseData['data']['message']['code']} and message: ${responseData['data']['message']['message']}');
      }
    } else {
      throw Exception(
          'Failed to verify OTP with status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/icons/swahilicardsQR.png",
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1ED760)
                      .withOpacity(0.8), // Spotify green with transparency
                  const Color(0xFF121212) // Spotify black
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  "Your network.",
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  "Is your networth.",
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Signup for free button
                ElevatedButton(
                  onPressed: _showPhoneNumberBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50C878),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize:
                        const Size(double.infinity, 50), // Full-width button
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text("SIGN UP FOR FREE"),
                ),
                const SizedBox(height: 20),
                // Continue with Google button
                ElevatedButton.icon(
                  //  await _preferencesHelper.setCompletedSteps(true);
                  // onPressed: () => _signInWithGoogle(context),
                  onPressed: () async {
                    await _preferencesHelper.setCompletedSteps(true);

                    _signInWithGoogle(context);
                  },
                  icon: const Icon(
                      Icons.accessibility), // Replace with the Google logo
                  label: const Text("CONTINUE WITH GOOGLE"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                // Continue with Facebook button
                ElevatedButton.icon(
                  onPressed: () async {
                    await _preferencesHelper.setCompletedSteps(true);
                    await _signInWithTwitter();
                  },
                  icon:
                      const Icon(Icons.face), // Replace with the Facebook logo
                  label: const Text("CONTINUE WITH X(TWITTER)"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Have an account?",
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () async {
                        await _showSignInBottomSheet();
                      },
                      child: const Text(
                        "SIGN IN",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
