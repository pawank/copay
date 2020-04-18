class PageModel {
  final String assetImagePath;
  final String text;
  PageModel({this.assetImagePath, this.text});
}

List<PageModel> pages = [
  PageModel(
    assetImagePath: 'assets/android/main.jpeg',
    text: 'Your landing dashboard.\n\nCreate new campaign, share and donate.',
  ),
  PageModel(
    assetImagePath: 'assets/android/requests.jpeg',
    text: 'Share and get help from friends.',
  ),
  PageModel(
      assetImagePath: 'assets/android/pay.jpeg',
      text: 'Pay donation to the needful.'),
];