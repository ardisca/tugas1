import 'package:flutter/material.dart';

import '../controller/master_office_controller.dart';

class MasterOfficePage extends StatefulWidget {
  const MasterOfficePage({super.key});

  @override
  State<MasterOfficePage> createState() => _MasterOfficePageState();
}

class _MasterOfficePageState extends State<MasterOfficePage> {
  MasterOfficeController officeController = MasterOfficeController();
  List dataView = [];

  @override
  void initState() {
    super.initState();
    dataView = officeController.office;
  }

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
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 16),
        itemCount: dataView.length,
        itemBuilder: (context, index) {
          Map data = dataView[index];
          return _renderData(context, data);
        },
        separatorBuilder: (BuildContext context, int index) => const SizedBox(
          height: 10,
        ),
      ),
    );
  }

  Widget _renderData(BuildContext context, Map data) {
    return InkWell(
      onTap: () => Navigator.pop(context, data),
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
                  Text(data['name'] ?? 'No Address'),
                  Text('${data['location']['address'] ?? 'No Time'}'),
                  Text(
                      'Lat: ${data['location']['lat']}, Long: ${data['location']['long']}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
