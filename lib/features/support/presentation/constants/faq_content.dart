class FaqItem {
  const FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

const List<FaqItem> kGeneralFaqItems = <FaqItem>[
  FaqItem(
    question: 'How many days will it take for my next car wash?',
    answer:
        "Our expert suggests that you should maintain your car wash at least twice a week in proper way. By this act your car always looks like a shiny new car. So, our team makes you tension free from your 'car maintenance'. Our extraordinary washes make it possible.",
  ),
  FaqItem(
    question: 'Do you wash all types of vehicles?',
    answer:
        'Yea sure, we wash all types of cars. But, we need at least 4-inch underground clearance. We also assure that all the latest equipment which we have are in working properly.',
  ),
  FaqItem(
    question:
        "Can i make a car wash for my newly painted car and it's safe or not?",
    answer:
        'We use organic and eco-friendly products, which will make your pained car fully secure in a wide range. Moreover this organic product increases gripy strongest in between the paint and car body. This is the result of increasing more shiny and age of the paint extra two years.',
  ),
  FaqItem(
    question: 'Is car wash for alloy wheels safe?',
    answer:
        "By using normal soaps and shampoos it's losing their shine due to harmful acid. But, our expert guided us to use organic wax and polishes which make evergreen protection layer in alloy wheels after applying it. Hard brushing makes scratches to alloy. So, we will not use any acid or hard brushes. We only use soft cloth or fabric cloth material and you alloys are 100% productive or safe.",
  ),
];
