import 'package:flutter/material.dart';
import 'package:task_management_todo/Screens/signup_screen.dart';
import 'package:task_management_todo/models/onboard_data.dart' show onboardingContents;


class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({Key? key}) : super(key: key);

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingContents.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (_, index) {
                  final content = onboardingContents[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          content.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Image
                        Expanded(
                          child: Image.asset(
                            content.image,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Subtitle (fixed for now)
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: "Small tasks, "),
                              TextSpan(
                                text: "BIG IMPACT ",
                                style: TextStyle(
                                  color: Color(0xFF6A5AE0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: " on your "),
                              TextSpan(
                                text: "Productivity",
                                style: TextStyle(
                                  color: Color(0xFF6A5AE0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Footer (different for last screen vs others)
                        if (_currentPage == onboardingContents.length - 1)
                          // ✅ Show Get Started only on last page
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:Color(0xFF6A5AE0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Get Started",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          // ✅ Show Skip + dots + Next on other pages
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _pageController.jumpToPage(
                                    onboardingContents.length - 1,
                                  );
                                },
                                child: const Text(
                                  "Skip",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  onboardingContents.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: _currentPage == index ? 12 : 8,
                                    height: _currentPage == index ? 12 : 8,
                                    decoration: BoxDecoration(
                                      color: _currentPage == index
                                          ?  Color(0xFF6A5AE0)
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeIn,
                                  );
                                },
                                child: const Text(
                                  "Next",
                                  style: TextStyle(
                                     color: Color(0xFF6A5AE0),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

