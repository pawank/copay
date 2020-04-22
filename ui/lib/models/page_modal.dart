class PageModel {
  final String assetImagePath;
  final String text;
  PageModel({this.assetImagePath, this.text});
}

List<PageModel> pages = [
  PageModel(
    assetImagePath: 'assets/android/main.png',
    text: 'Your landing dashboard.\n\nCreate new campaign, share and donate.',
  ),
  PageModel(
    assetImagePath: 'assets/android/raise_request.png',
    text: 'Raise a Request',
  ),
  PageModel(
      assetImagePath: 'assets/android/pay.png',
      text: 'Share with friends and \nPay the beneficiary via UPI'),
];