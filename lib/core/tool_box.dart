// lib/core/tool_box.dart
import 'package:dio/dio.dart';

class ToolBox {
  // 1. 填入你刚才申请的高德 Web 服务 API Key
  static const String _mapApiKey = "88ef6f0a034af78ee56fae50b060c855"; 

  static Future<String> getRealTimeTraffic(String destination) async {
    final dio = Dio();
    try {
      // 2. 先调用地理编码 API：把文字（比如“西湖”）转成坐标（经纬度）
      final geoRes = await dio.get(
        'https://restapi.amap.com/v3/geocode/geo',
        queryParameters: {'key': _mapApiKey, 'address': destination},
      );

      if (geoRes.data['status'] == '1' && (geoRes.data['geocodes'] as List).isNotEmpty) {
        String location = geoRes.data['geocodes'][0]['location']; // 拿到经纬度，例如 "116.48,39.99"

        // 3. 调用路径规划 API：查询从当前位置（这里默认一个起点）到目的地的交通情况
        // 这里的 strategy=10 代表避开拥堵
        final routeRes = await dio.get(
          'https://restapi.amap.com/v3/direction/driving',
          queryParameters: {
            'key': _mapApiKey,
            'origin': '116.481028,39.989643', // 这里你可以暂时写死一个起点，或者后期接入 GPS
            'destination': location,
            'extensions': 'all', // 获取详细信息
          },
        );

        if (routeRes.data['status'] == '1') {
          var route = routeRes.data['route']['paths'][0];
          String distance = (double.parse(route['distance']) / 1000).toStringAsFixed(1);
          String duration = (double.parse(route['duration']) / 60).toStringAsFixed(0);
          
          // 4. 返回真实的数据给 AI
          return "【高德实时数据】距离目的地约 $distance 公里。当前路况下预计耗时 $duration 分钟。路线标签：${route['strategy']}。";
        }
      }
      return "抱歉，高德地图没能找到这个地方。";
    } catch (e) {
      return "高德 API 连线失败：$e";
    }
  }
}