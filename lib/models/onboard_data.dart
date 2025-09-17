class OnBoarding {
  final String title;
  final String description;
  final String image;

  OnBoarding({
    required this.title,
    required this.description,
    required this.image,
  });
}

List<OnBoarding> onboardingContents = [
  OnBoarding(
    title: 'Welcome to TaskMate',
    description: 'Your personal companion to organize tasks and boost productivity.',
    image: 'assets/images/1.png',
  ),
  OnBoarding(
    title: 'Plan Your Day',
    description: 'Create tasks and set priorities to stay on top of your schedule.',
    image: 'assets/images/2.png',
  ),
  OnBoarding(
    title: 'Track Your Progress',
    description: 'Mark tasks as done and watch your productivity grow.',
    image: 'assets/images/3.png',
  ),
  OnBoarding(
    title: 'Stay Organized, Achieve More',
    description: 'Manage your tasks effortlessly and reach your goals every day.',
    image: 'assets/images/4.png',
  ),
];
