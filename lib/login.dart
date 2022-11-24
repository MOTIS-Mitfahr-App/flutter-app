import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_app/email_field.dart';
import 'package:flutter_app/forgot_password.dart';
import 'package:flutter_app/loading_button.dart';
import 'package:flutter_app/password_field.dart';
import 'package:flutter_app/register.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Login"),
        ),
        body: const Center(
          child: CustomScrollView(physics: ClampingScrollPhysics(), slivers: [
            SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: LoginForm(),
                ))
          ]),
        ));
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  ButtonState _state = ButtonState.idle;

  void onSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _state = ButtonState.loading;
      });
      try {
        await supabaseClient.auth.signInWithPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        setState(() {
          _state = ButtonState.success;
        });
      } on AuthException catch (e) {
        fail();
        // looks weird but needed later for i18n
        String text = e.statusCode == '400'
            ? (e.message.contains("credentials")
                ? "Invalid credentials"
                : "Please confirm your email address")
            : "Something went wrong";

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
        ));
      }
    } else {
      fail();
    }
  }

  void fail() async {
    setState(() {
      _state = ButtonState.fail;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _state = ButtonState.idle;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing:
            _state == ButtonState.loading || _state == ButtonState.success,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(child: Container()),
              EmailField(controller: emailController),
              const SizedBox(height: 15),
              PasswordField(
                labelText: "Password",
                hintText: "Enter your password",
                controller: passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen(
                            initialEmail: emailController.text)));
                  },
                  child: const Text("Forgot password?")),
              Hero(
                  tag: "LoginButton",
                  transitionOnUserGestures: true,
                  child: LoadingButton(onPressed: onSubmit, state: _state)),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const RegisterScreen()));
                      },
                      child: const Text("No account yet? Register")),
                ),
              )
            ],
          ),
        ));
  }
}