import 'package:cloud_firestore/cloud_firestore.dart';

class RouteUploader {
  static Future<void> uploadGongabuToMaitideviRoute() async {
    final firestore = FirebaseFirestore.instance;
    final routeData = {
      "start": "Kalanki",
      "end": "Gongabu New Bus Station Parking, Kathmandu 44600",
      "bus": "Mahanagar Yatayat",
      "coordinates": [
        { "Lat": 27.693148, "Lng": 85.280928 },
        { "Lat": 27.693328, "Lng": 85.281797 },
        { "Lat": 27.696014, "Lng": 85.281684 },
        { "Lat": 27.698684, "Lng": 85.281469 },
        { "Lat": 27.704174, "Lng": 85.282102 },
        { "Lat": 27.707575, "Lng": 85.282542 },
        { "Lat": 27.715762, "Lng": 85.283443 },
        { "Lat": 27.716579, "Lng": 85.283604 },
        { "Lat": 27.718042, "Lng": 85.283894 },
        { "Lat": 27.719751, "Lng": 85.287091 },
        { "Lat": 27.720891, "Lng": 85.289365 },
        { "Lat": 27.723987, "Lng": 85.295738 },
        { "Lat": 27.725032, "Lng": 85.298485 },
        { "Lat": 27.726475, "Lng": 85.303678 },
        { "Lat": 27.727463, "Lng": 85.304944 },
        { "Lat": 27.728014, "Lng": 85.305287 },
        { "Lat": 27.730145, "Lng": 85.305410 },
        { "Lat": 27.734665, "Lng": 85.305603 },
        { "Lat": 27.735311, "Lng": 85.306097 },
        { "Lat": 27.735427, "Lng": 85.306405 },
        { "Lat": 27.735256, "Lng": 85.307843 },
        { "Lat": 27.735284, "Lng": 85.307422 }
      ],
      "stops": [
        { "Lat": 27.704174, "Lng": 85.282102, "title": "Soaltee Dobato Chowk" },
        { "Lat": 27.707575, "Lng": 85.282542, "title": "Sano" },
        { "Lat": 27.716579, "Lng": 85.283604, "title": "Swayambhu Bus Stop" },
        { "Lat": 27.719751, "Lng": 85.287091, "title": "Thulo Bharyang Bus Stop" },
        { "Lat": 27.725032, "Lng": 85.298485, "title": "Banasthali Bus Stop" },
        { "Lat": 27.727463, "Lng": 85.304944, "title": "Balaju Chowk" },
        { "Lat": 27.735311, "Lng": 85.306097, "title": "Machha Pokhari" }
      ]
    };

    await firestore.collection('route').doc('kalanki to gangabu   ').set(routeData);
    print('✅ Maitidevi–Gongabu route uploaded.');

  }
}
