import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'image_view.dart';

class HistoryAttendancePage extends StatelessWidget {
  const HistoryAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _renderBody()),
    );
  }

  Widget _renderBody() {
    return Column(
      children: [_renderSearch(), _renderListData()],
    );
  }

  Widget _renderSearch() {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 16),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ]),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          contentPadding: const EdgeInsets.all(16.0),
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _renderListData() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          return ListView.separated(
            padding:
                const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _renderData(context, data);
            },
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(
              height: 10,
            ),
          );
        },
      ),
    );
  }

  Widget _renderData(BuildContext context, Map<String, dynamic> data) {
    return InkWell(
      onTap: () => data['image'] != "null"
          ? Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageView(url: data['image']),
              ))
          : ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image Kosong'),
                backgroundColor: Colors.red,
              ),
            ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ], color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.amber, borderRadius: BorderRadius.circular(8)),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['position']['address'] ?? 'No Address'),
                  Text('${data['time'].toDate() ?? 'No Time'}'),
                  Text(
                      'Lat: ${data['position']['lat']}, Long: ${data['position']['long']}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
