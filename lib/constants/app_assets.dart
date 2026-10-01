import '../services/app_envirionment_service.dart';

class AppAssets {
  AppAssets._();

  // should render as per the app flavor
  static const String lifenityLogo = 'assets/images/lifenity-logo.png';
  static const String appBetaIcon = 'assets/app-icons/oms-beta.png';
  static const String appDevIcon = 'assets/app-icons/oms-dev.png';

  static String get appIcon => AppEnvironment.isBeta
      ? AppAssets.appBetaIcon
      : AppEnvironment.isDev
      ? AppAssets.appDevIcon
      : lifenityLogo;

  // icons
  static const String userIcon = 'assets/icons/user-square-rounded.svg';
  static const String inventoryIcon = 'assets/icons/inventory.svg';
  static const String addPatient = 'assets/icons/add-patient.svg';
  static const String medicalPress = 'assets/icons/medical-pres.svg';
  static const String medicalPlus = 'assets/icons/medical-plus.svg';
  static const String testTube = 'assets/icons/test-tube.svg';
  static const String patient = 'assets/icons/patient.svg';
  static const String home = 'assets/icons/home.svg';
  static const String checkIcon = 'assets/icons/check.svg';
  static const String laboratory = 'assets/icons/lab.svg';
  static const String facility = 'assets/icons/facility.svg';
  static const String doctor = 'assets/icons/doctor.svg';
  static const String healthReportSvg = 'assets/icons/health-notepad.svg';
  static const String medicalUnitIcon = 'assets/icons/medical-unit.svg';
  static const String calendarIcon = 'assets/icons/calendar_icon.svg';
  static const String clockIcon = 'assets/icons/clock.svg';
  static const String calendarClockIcon = 'assets/icons/calendar-clock.svg';
  static const String singleUserIcon = 'assets/icons/user.png';
  static const String headsetIcon = 'assets/icons/headset.svg';
  static const String infoIcon = 'assets/icons/info_square.svg';
  static const String messagesIcon = 'assets/icons/messages.svg';
  static const String logOutIcon = 'assets/icons/logout_icon.svg';
  static const String cameraIcon = 'assets/icons/camera.svg';
  static const String idProofIcon = 'assets/icons/id.svg';
  static const String questionIcon = 'assets/icons/question.svg';
  static const String mapPinIcon = 'assets/icons/map-pin.svg';
  static const String mobileIcon = 'assets/icons/device-mobile.svg';
  static const String email = 'assets/icons/email.svg';
  static const String location = 'assets/icons/location.svg';
  static const String fileNoteIcon = 'assets/icons/file-text.svg';
  static const String lockIcons = 'assets/icons/lock-square-rounded.svg';
  static const String barcodeIcon = 'assets/icons/barcode.svg';
  static const String microscope = 'assets/icons/microscope.svg';
  static const String labTechnician = 'assets/icons/lab-tech.svg';
  static const String medBackpack = 'assets/icons/med-backpack.svg';
  static const String medHandBag = 'assets/icons/med-hand-bag.svg';
  static const String rejectFileIcon = 'assets/icons/reject-file.svg';
  static const String forwardIcon = 'assets/icons/forward.svg';
  static const String backwardIcon = 'assets/icons/backward.svg';
  static const String twoTestTubes = 'assets/icons/twoTestTubes.svg';
  static const String deliveryMan = 'assets/icons/delivery-man.svg';
  static const String whatsAppIcon = 'assets/icons/whatsappIcon.svg';
  static const String phlebotomistIcon = 'assets/icons/phlebo-icon.svg';
  static const String connectorIcon = 'assets/icons/connector-icon.svg';
  static const String nurseIcon = 'assets/icons/nurse.svg';
  static const String userCircle = 'assets/icons/user-circle.svg';
  static const String calendarEvent = 'assets/icons/calendar-event.svg';
  static const String phoneIcon = 'assets/icons/phone.svg';
  static const String testPipe = 'assets/icons/test-pipe-2.svg';
  static const String report = 'assets/icons/report.svg';
  static const String barcode = 'assets/icons/barcode_n.svg';
  static const String eyeView = 'assets/icons/eye_view.svg';
  static const String whatsapp = 'assets/icons/whatsapp.svg';
  static const String share = 'assets/icons/share.svg';
  static const String arrowBackward = 'assets/icons/arrow-backwards.svg';

  /// dashboard icons'
  static const String deliveryBoyIcon = 'assets/images/delivery-boy.png';
  static const String liveTrackingIcon = 'assets/images/live-tracking.png';

  /// Dashboard cards

  static const String collectSampleIcon =
      'assets/dashboard_icons/collect-sample-icon.png';
  static const String manageOrderIcon =
      'assets/dashboard_icons/manage-order-icon.png';
  static const String bagHistoryIcon =
      'assets/dashboard_icons/collect-destination-bag.png';
      // 'assets/dashboard_icons/bag-history-icon.png';
  static const String sampleRecollectionIconOg =
      'assets/dashboard_icons/sample-recollection-icon.png';
  static const String collectedBagsIcon =
      'assets/dashboard_icons/collected-bags.png';
  static const String collectBagIcon = 'assets/dashboard_icons/collect-bag.png';
  static const String collectDestinationBag =
      'assets/dashboard_icons/collect-destination-bag.png';
  static const String acceptInLabIcon =
      'assets/dashboard_icons/accept-in-lab.png';

  /// sample live tracking dashboard
  static const String bagOpenedIcon = 'assets/images/bag-opened-icon.jpg';
  static const String bagCollectedIcon = 'assets/images/collected-icon.jpg';
  static const String bagTransferIcon = 'assets/images/transfer-icon.jpg';
  static const String bagHandoverIcon = 'assets/images/handover-icon.jpg';
  static const String bagSubmittedIcon = 'assets/images/submitted-icon.jpg';
  static const String bagAcceptedIcon = 'assets/images/accepted-icon.jpg';
  static const String bagClosedIcon = 'assets/images/closed-icon.jpg';

  static const String attentionNeeded = 'assets/images/attention-needed.png';
  static const String completedToday = 'assets/images/completed-today.png';
  static const String inTransit = 'assets/images/in-transit.png';
  static const String pickupAwaiting = 'assets/images/pickup-awaiting.png';
  static const String splashScreen = 'assets/images/splash-screen.png';

  // camp
  static const String medicalHeartNotepad = 'medical-file-heart.svg';
}
