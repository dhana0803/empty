import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'CustomerPage.dart';

const String shopitText = 'ShopGenie';
const String coat = 'Easy way to buy quality products';
const String logintext = "Login";

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        home: Homepage(),
      ),
    ),
  );
}

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void navigateTo(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}

class Homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 145, 208, 240),
      body: Center(
        child: Container(
          width: 1150,
          height: 650,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 110),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopitText,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      coat,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PhoneNumberInputSection(), // Always display phone number input
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.only(right: 10, top: 60),
                child: Image.asset(
                  'assets/images/pimg.png',
                  width: 500,
                  height: 500,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhoneNumberInputSection extends StatefulWidget {
  @override
  _PhoneNumberInputSectionState createState() => _PhoneNumberInputSectionState();
}

class _PhoneNumberInputSectionState extends State<PhoneNumberInputSection> {
  TextEditingController phoneNumberController = TextEditingController();
  bool isPhoneNumberValid = false;
  bool keepMeLoggedIn = false;

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }

  void _showOTPDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PopupOTPValidation(
        phoneNumber: phoneNumberController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 234, 241, 245),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.only(top: 80, left: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            logintext,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 300,
              child: IntlPhoneField(
                controller: phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(),
                  ),
                ),
                initialCountryCode: 'IN',
                onChanged: (phone) {
                  setState(() {
                    isPhoneNumberValid = phone.number.length >= 10;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            title: const Text('Keep me logged in'),
            value: keepMeLoggedIn,
            onChanged: (bool? value) {
              setState(() {
                keepMeLoggedIn = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: isPhoneNumberValid ? () => _showOTPDialog(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPhoneNumberValid
                    ? const Color.fromARGB(255, 240, 196, 100)
                    : const Color.fromARGB(255, 231, 228, 223),
              ),
              child: Text(
                'Send OTP',
                style: TextStyle(
                  color: isPhoneNumberValid ? Colors.black : const Color.fromARGB(255, 231, 228, 223),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PopupOTPValidation extends StatefulWidget {
  final String phoneNumber;

  const PopupOTPValidation({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  _PopupOTPValidationState createState() => _PopupOTPValidationState();
}

class _PopupOTPValidationState extends State<PopupOTPValidation> {
  static const int otpLength = 6; // Define OTP length
  List<TextEditingController> otpControllers = List.generate(otpLength, (index) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(otpLength, (index) => FocusNode());
  String? verificationId;
  int _remainingTime = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendOTP();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _sendOTP() async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      await auth.verifyPhoneNumber(
        phoneNumber: '+91${widget.phoneNumber}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => CustomerPage()),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('OTP Sent to +91 ${widget.phoneNumber}')),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            this.verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (verificationId != null) {
      String otp = otpControllers.map((controller) => controller.text).join();
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId!,
          smsCode: otp,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => CustomerPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to authenticate: $e')),
        );
      }
    }
  }

  void _resendOTP() {
    setState(() {
      _remainingTime = 60;
    });
    _startTimer();
    _sendOTP();
  }

  @override
  void dispose() {
    otpControllers.forEach((controller) => controller.dispose());
    focusNodes.forEach((node) => node.dispose());
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter OTP'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'OTP is sent to +91 ${widget.phoneNumber}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(otpLength, (index) {
              return Container(
                width: 40,
                margin: EdgeInsets.symmetric(horizontal: 5),
                child: TextField(
                  controller: otpControllers[index],
                  focusNode: focusNodes[index],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  obscureText: true,
                  obscuringCharacter: '*',
                  onChanged: (value) {
                    if (value.length == 1) {
                      if (index < otpLength - 1) {
                        FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                      } else {
                        FocusScope.of(context).unfocus();
                      }
                    }
                  },
                ),
              );
            }),
          ),
          SizedBox(height: 20),
          Text(
            'Remaining time: ${_remainingTime}s',
            style: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 149, 20, 20)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 240, 196, 100),
            ),
            child: Text(
              'Verify OTP',
              style: TextStyle(color: Colors.black),
            ),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: _remainingTime == 0 ? _resendOTP : null,
            child: Text('Resend OTP'),
          ),
        ],
      ),
    );
  }
}
