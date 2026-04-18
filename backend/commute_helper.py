"""
高德地图通勤助手模块
提供路线规划、POI搜索、附近查询等功能
"""
import requests
import re
import os

class CommuteHelper:
    def __init__(self):
        self.api_key = os.getenv("GAODE_KEY", "86c79bd6eb9a5f4c02822016fe3bdb49")
        self.base_url = "https://restapi.amap.com/v3"
        self._geocode_cache = {}  # 地理编码缓存
        self._last_request_time = 0  # 上次请求时间

    def handle_request(self, question):
        """处理通勤助手请求"""
        try:
            question_lower = question.lower()

            # 判断用户意图
            if "搜索" in question or "找" in question or "在哪里" in question:
                return self.poi_search(question)
            elif "路线" in question or "怎么走" in question or "到" in question:
                # 检查是否为多站点路线
                stops = self._extract_multi_stops(question)
                if len(stops) >= 2:
                    return self.multi_stop_route(question, stops)
                return self.route_planning(question)
            elif "公交" in question:
                return self.bus_route(question)
            elif "驾车" in question or "开车" in question:
                return self.driving_route(question)
            elif "步行" in question or "走路" in question:
                return self.walking_route(question)
            elif "附近" in question:
                return self.nearby_search(question)
            else:
                return self.general_help()

        except Exception as e:
            return {
                "content": f"通勤助手处理失败: {str(e)}\n\n您可以尝试以下功能：\n1. 搜索地点：搜索附近的咖啡店\n2. 路线规划：从北京站到天安门的路线\n3. 公交查询：从家到公司的公交路线\n4. 附近查询：附近的餐厅",
                "source": "通勤助手"
            }

    def poi_search(self, question):
        """POI 搜索"""
        try:
            # 提取搜索关键词
            keywords = self._extract_keywords(question, ["搜索", "找", "在哪里"])
            city = self._extract_city(question)

            url = f"{self.base_url}/place/text"
            params = {
                "key": self.api_key,
                "keywords": keywords,
                "city": city if city else "全国",
                "output": "json"
            }

            response = requests.get(url, params=params, timeout=10)
            result = response.json()

            if result.get("status") == "1" and result.get("pois"):
                pois = result["pois"][:5]  # 返回前5个结果
                content = f"[搜索] 搜索 \"{keywords}\" 的结果：\n\n"

                for i, poi in enumerate(pois, 1):
                    name = poi.get("name", "未知")
                    address = poi.get("address", "无详细地址")
                    distance = poi.get("distance", "未知")
                    location = poi.get("location", "")

                    content += f"{i}. {name}\n"
                    content += f"   地址: {address}\n"
                    if distance != "未知":
                        content += f"   距离: {distance}米\n"
                    content += f"   坐标: {location}\n\n"

                content += f"提示：可以说\"从当前位置到{pois[0].get('name', '目的地')}的路线\"来获取导航信息"

                return {"content": content, "source": "通勤助手"}
            else:
                return {"content": f"[错误] 未找到 \"{keywords}\" 的相关结果\n\n建议：\n1. 检查关键词是否正确\n2. 尝试使用更通用的名称\n3. 指定城市范围", "source": "通勤助手"}

        except Exception as e:
            return {"content": f"POI搜索失败: {str(e)}", "source": "通勤助手"}

    def route_planning(self, question):
        """通用路线规划"""
        try:
            # 提取起点和终点
            locations, origin_name, dest_name = self._extract_locations(question)

            if len(locations) < 2 or not all(locations):
                missing = []
                if not locations[0] if len(locations) >= 1 else True:
                    missing.append(f"起点「{origin_name}」")
                if not locations[1] if len(locations) >= 2 else True:
                    missing.append(f"终点「{dest_name}」")
                return {
                    "content": f"[错误] 无法定位地址：{', '.join(missing)}\n\n请提供更准确的地名，如：\n• 从杭州火车站到西湖\n• 从北京站到天安门\n• 从家到公司",
                    "source": "通勤助手"
                }

            origin = locations[0]
            destination = locations[1]

            # 驾车路线规划
            url = f"{self.base_url}/direction/driving"
            params = {
                "key": self.api_key,
                "origin": origin,
                "destination": destination,
                "output": "json"
            }

            response = requests.get(url, params=params, timeout=10)
            result = response.json()

            if result.get("status") == "1" and result.get("route", {}).get("paths"):
                path = result["route"]["paths"][0]
                distance = path.get("distance", "未知")
                duration = path.get("duration", "未知")
                steps = path.get("steps", [])

                content = f"[驾车路线] 从「{origin_name}」到「{dest_name}」的路线：\n\n"
                content += f"总距离: {distance}米\n"
                content += f"预计时间: {int(int(duration)/60)}分钟\n\n"
                content += "主要路段：\n"

                for i, step in enumerate(steps[:10], 1):  # 只显示前10步
                    instruction = step.get("instruction", "继续行驶")
                    content += f"{i}. {instruction}\n"

                if len(steps) > 10:
                    content += f"... 还有{len(steps)-10}个转弯\n"

                content += "\n其他出行方式：\n"
                content += "• 说\"公交从起点到终点\"查看公交路线\n"
                content += "• 说\"步行从起点到终点\"查看步行路线"

                return {"content": content, "source": "通勤助手"}
            else:
                return {"content": f"[错误] 路线规划失败，可能是：\n1. 起点或终点地址不明确\n2. 路线无法通过道路连接\n3. 网络连接问题\n\n请提供更详细的地址信息", "source": "通勤助手"}

        except Exception as e:
            return {"content": f"路线规划失败: {str(e)}", "source": "通勤助手"}

    def bus_route(self, question):
        """公交路线查询"""
        try:
            locations, origin_name, dest_name = self._extract_locations(question)

            if len(locations) < 2 or not all(locations):
                return {"content": "[错误] 请提供起点和终点\n\n示例：从北京站到天安门的公交", "source": "通勤助手"}

            url = f"{self.base_url}/route/transit/integrated"
            params = {
                "key": self.api_key,
                "origin": locations[0],
                "destination": locations[1],
                "city": self._extract_city(question),
                "output": "json"
            }

            response = requests.get(url, params=params, timeout=10)
            result = response.json()

            if result.get("status") == "1" and result.get("route", {}).get("transits"):
                transits = result["route"]["transits"][:3]  # 显示前3个方案
                content = "[公交路线] 公交路线方案：\n\n"

                for i, transit in enumerate(transits, 1):
                    duration = transit.get("duration", "0")
                    walking_distance = transit.get("walking_distance", "0")
                    segments = transit.get("segments", [])

                    content += f"方案{i}: 预计{int(int(duration)/60)}分钟 步行{int(walking_distance)}米\n"

                    for j, segment in enumerate(segments):
                        if segment.get("walking", {}).get("steps"):
                            content += f"  • 步行 {segment['walking']['distance']}米\n"
                        if segment.get("bus", {}).get("buslines"):
                            busline = segment["bus"]["buslines"][0]
                            name = busline.get("name", "未知")
                            content += f"  • 乘坐 {name}\n"

                    content += "\n"

                return {"content": content, "source": "通勤助手"}
            else:
                return {"content": "[错误] 未找到合适的公交路线\n\n建议：\n1. 检查起终点是否在同一城市\n2. 尝试使用驾车或步行方案", "source": "通勤助手"}

        except Exception as e:
            return {"content": f"公交查询失败: {str(e)}", "source": "通勤助手"}

    def driving_route(self, question):
        """驾车路线"""
        return self.route_planning(question)

    def walking_route(self, question):
        """步行路线"""
        try:
            locations, origin_name, dest_name = self._extract_locations(question)

            if len(locations) < 2 or not all(locations):
                return {"content": "[错误] 请提供起点和终点\n\n示例：步行从北京站到天安门", "source": "通勤助手"}

            url = f"{self.base_url}/route/walking"
            params = {
                "key": self.api_key,
                "origin": locations[0],
                "destination": locations[1],
                "output": "json"
            }

            response = requests.get(url, params=params, timeout=10)
            result = response.json()

            if result.get("status") == "1" and result.get("route", {}).get("paths"):
                path = result["route"]["paths"][0]
                distance = path.get("distance", "0")
                duration = path.get("duration", "0")
                steps = path.get("steps", [])

                content = f"[步行路线] 步行路线：\n\n"
                content += f"总距离: {distance}米\n"
                content += f"预计时间: {int(int(duration)/60)}分钟\n\n"
                content += "步行指引：\n"

                for i, step in enumerate(steps[:15], 1):
                    instruction = step.get("instruction", "继续行走")
                    content += f"{i}. {instruction}\n"

                content += "\n提示：步行路线适合短距离出行，长距离建议使用公交或驾车方案。"

                return {"content": content, "source": "通勤助手"}
            else:
                return {"content": "[错误] 步行路线规划失败\n\n可能原因：\n1. 距离过远（建议使用其他出行方式）\n2. 起终点地址不明确", "source": "通勤助手"}

        except Exception as e:
            return {"content": f"步行路线查询失败: {str(e)}", "source": "通勤助手"}

    def nearby_search(self, question):
        """附近搜索"""
        try:
            keywords = self._extract_keywords(question, ["附近"])
            city = self._extract_city(question)

            url = f"{self.base_url}/place/around"
            params = {
                "key": self.api_key,
                "keywords": keywords,
                "city": city if city else "全国",
                "output": "json",
                "radius": "3000"  # 默认3公里范围
            }

            response = requests.get(url, params=params, timeout=10)
            result = response.json()

            if result.get("status") == "1" and result.get("pois"):
                pois = result["pois"][:5]
                content = f"[附近搜索] 附近的{keywords}：\n\n"

                for i, poi in enumerate(pois, 1):
                    name = poi.get("name", "未知")
                    address = poi.get("address", "无详细地址")
                    distance = poi.get("distance", "未知")

                    content += f"{i}. {name}\n"
                    content += f"   地址: {address}\n"
                    if distance != "未知":
                        content += f"   距离: {distance}米\n"
                    content += "\n"

                content += f"提示：可以说\"从当前位置到{pois[0].get('name', '目的地')}的路线\"获取导航"

                return {"content": content, "source": "通勤助手"}
            else:
                return {"content": f"[错误] 附近未找到{keywords}\n\n建议：扩大搜索范围或更换关键词", "source": "通勤助手"}

        except Exception as e:
            return {"content": f"附近搜索失败: {str(e)}", "source": "通勤助手"}

    def general_help(self):
        """通用通勤助手查询"""
        help_text = """[通勤助手] 使用指南：

基础功能
• 搜索地点：搜索附近的咖啡店 / 找加油站
• 路线规划：从A到B的路线 / A到B怎么走
• 公交查询：从A到B的公交路线
• 驾车导航：从A到B怎么开车
• 步行路线：从A到B步行怎么走

高级功能
• 附近搜索：附近的餐厅 / 附近的停车场
• 连续搜索：沿途搜索加油站 / 路上找休息区

使用示例
1. "搜索北京三里屯的咖啡店"
2. "从北京站到天安门的路线"
3. "从家到公司的公交路线"
4. "附近的加油站"
5. "连续搜索沿途餐厅"

请告诉我您的具体需求！"""

        return {"content": help_text, "source": "通勤助手"}

    def _extract_keywords(self, question, exclude_words):
        """提取关键词，排除常用词"""
        keywords = question
        for word in exclude_words:
            keywords = keywords.replace(word, "")
        return keywords.strip()

    def _extract_city(self, question):
        """提取城市信息"""
        # 常见城市列表
        cities = ["北京", "上海", "广州", "深圳", "杭州", "成都", "重庆", "西安", "南京", "武汉", "天津", "苏州", "长沙", "郑州", "济南", "青岛", "大连", "沈阳", "哈尔滨", "长春"]
        for city in cities:
            if city in question:
                return city
        return ""

    def _geocode_address(self, address):
        """将文字地址转换为经纬度坐标"""
        if not address or not address.strip():
            return None

        address = address.strip()

        # 检查缓存
        if address in self._geocode_cache:
            return self._geocode_cache[address]

        city = self._extract_city(address)

        # 特殊地点城市映射 - 直接构造带城市的地址
        city_hint = {
            "西湖": "杭州市西湖",
            "天安门": "北京市天安门",
            "故宫": "北京市故宫",
            "长城": "北京市长城",
            "外滩": "上海市外滩",
            "陆家嘴": "上海市陆家嘴",
            "东方明珠": "上海市东方明珠",
            "解放碑": "重庆市解放碑",
        }

        # 对于知名地点，自动使用带城市的完整地址
        geocode_address = address
        for place, hint in city_hint.items():
            if place in address and not any(c in address for c in ["杭州市", "北京市", "上海市", "重庆市"]):
                geocode_address = hint
                break

        url = f"{self.base_url}/geocode/geo"
        params = {
            "key": self.api_key,
            "address": geocode_address,
            "city": city if city else "",
            "output": "json"
        }
        try:
            resp = requests.get(url, params=params, timeout=10)
            result = resp.json()

            if result.get("status") == "1" and result.get("geocodes"):
                location = result["geocodes"][0].get("location", "")
                if location:
                    # 存入缓存
                    self._geocode_cache[address] = location
                    return location
        except Exception:
            pass
        return None

    def _extract_locations(self, question):
        """
        从问题中提取起点和终点，并转换为经纬度坐标
        返回 (locations, origin_name, dest_name) 元组
        """
        # 匹配 "从A到B" 格式
        match = re.search(r'从(.+?)到(.+)', question)
        if not match:
            return [], None, None

        origin_name = match.group(1).strip()
        dest_name = match.group(2).strip()

        # 使用地理编码获取坐标
        origin = self._geocode_address(origin_name)
        dest = self._geocode_address(dest_name)

        # 如果地理编码失败，尝试用POI搜索获取坐标
        if not origin:
            origin = self._poi_get_first_location(origin_name)
        if not dest:
            dest = self._poi_get_first_location(dest_name)

        return [origin, dest], origin_name, dest_name

    def _poi_get_first_location(self, keyword):
        """通过POI搜索获取第一个结果的坐标"""
        try:
            city = self._extract_city(keyword)
            url = f"{self.base_url}/place/text"
            params = {
                "key": self.api_key,
                "keywords": keyword,
                "city": city if city else "全国",
                "output": "json"
            }
            resp = requests.get(url, params=params, timeout=10)
            result = resp.json()
            if result.get("status") == "1" and result.get("pois") and len(result["pois"]) > 0:
                location = result["pois"][0].get("location", "")
                if location:
                    return location
        except Exception:
            pass
        return None

    def _extract_multi_stops(self, question):
        """
        从问题中提取多个途经点
        """
        q = question.strip()

        # 去掉 "从" 开头
        if q.startswith("从"):
            q = q[1:]

        # 去掉末尾的吃饭等
        for suffix in ["吃个饭", "吃饭", "用餐"]:
            if q.endswith(suffix):
                q = q[:-len(suffix)]

        # 用正则匹配所有站点
        # 匹配模式：可选前缀(然后/再去/再到/接着) + 非贪婪内容
        # 分隔符：到/再去/然后去/再到/接着去/然后到
        pattern = r'([再到|再去|然后到|然后去|接着去]+)?([^再到|再去|然后到|然后去|接着去|到]+)'
        matches = re.findall(pattern, q)

        stops = []
        for match in matches:
            # match[0] = 前缀(如 "再到"), match[1] = 站点名
            stop = match[1].strip()
            # 去掉可能的前缀
            for p in ["再到", "再去", "然后到", "然后去", "接着去", "去"]:
                if stop.startswith(p):
                    stop = stop[len(p):].strip()
                    break
            if stop:
                stops.append(stop)

        if len(stops) >= 2:
            return stops

        return []

    def multi_stop_route(self, question, stops):
        """
        多站点路线规划
        显示每个站点的到达时间、距离、详细路线
        """
        try:
            if len(stops) < 2:
                return {"content": "请提供至少两个地点用于路线规划", "source": "通勤助手"}

            # 获取每个站点的坐标
            stop_locations = []
            stop_display_names = []

            for i, stop_name in enumerate(stops):
                location = None
                display_name = stop_name

                if i == 0:
                    # 第一个站点，用地理编码
                    location = self._geocode_address(stop_name)
                    if not location:
                        location = self._poi_get_first_location(stop_name)
                else:
                    # 后续站点
                    # 如果是泛指地点（如"汉堡店"），在上一站附近搜索
                    generic_keywords = ["汉堡店", "餐厅", "饭店", "咖啡店", "奶茶店", "超市", "便利店", "酒店", "银行", "厕所", "卫生间", "停车场", "加油站"]
                    is_generic = any(kw in stop_name for kw in generic_keywords)

                    if is_generic:
                        # 在上一站附近搜索
                        prev_loc = stop_locations[i-1][1]
                        nearby_pois = self.poi_search_nearby(prev_loc, stop_name, radius=2000)
                        if nearby_pois:
                            location = nearby_pois[0].get("location", "")
                            if location:
                                poi_name = nearby_pois[0].get("name", "")
                                poi_address = nearby_pois[0].get("address", "未知地址")
                                display_name = f"{stop_name}（推荐：{poi_name}）"
                                print(f"[DEBUG] 在上一站附近找到 {stop_name}: {poi_name} @ {location}")

                    # 如果附近搜索失败，再用全局搜索
                    if not location:
                        location = self._geocode_address(stop_name)
                    if not location:
                        location = self._poi_get_first_location(stop_name)

                stop_locations.append((stop_name, location))
                stop_display_names.append(display_name)

            # 检查哪些站点无法定位
            failed_stops = [name for name, loc in stop_locations if not loc]
            if failed_stops:
                return {
                    "content": f"无法定位以下地点：{', '.join(failed_stops)}\n\n请提供更详细或更准确的地址名称",
                    "source": "通勤助手"
                }

            # 计算每段路线
            segments = []
            total_distance = 0
            total_duration = 0

            for i in range(len(stops) - 1):
                origin_name, origin_loc = stop_locations[i]
                dest_name, dest_loc = stop_locations[i + 1]
                dest_display = stop_display_names[i + 1]

                segment_info = self._get_route_segment(origin_loc, dest_loc, origin_name, dest_name)
                if segment_info:
                    segments.append({
                        "from": origin_name,
                        "to": dest_display,
                        "to_raw": dest_name,
                        "distance": segment_info["distance"],
                        "duration": segment_info["duration"],
                        "steps": segment_info["steps"][:5],  # 只取前5步
                        "all_steps": segment_info["steps"]
                    })
                    total_distance += segment_info["distance"]
                    total_duration += segment_info["duration"]

            if not segments:
                return {"content": "路线规划失败，请稍后重试", "source": "通勤助手"}

            # 构建回复内容
            content = f"🗺️ 【多站点路线规划】\n\n"
            content += f"📍 途经 {len(stops)} 个地点：{' → '.join(stops)}\n\n"
            content += f"📊 总路程：{total_distance}米 | 预计总时间：{total_duration//60}分钟\n\n"
            content += "━" * 20 + "\n\n"

            for i, seg in enumerate(segments, 1):
                duration_min = seg["duration"] // 60
                content += f"🚗 第{i}段：{seg['from']} ➜ {seg['to']}\n"
                content += f"   距离：{seg['distance']}米 | 预计时间：{duration_min}分钟\n\n"

                content += "   📌 路线指引：\n"
                for j, step in enumerate(seg["steps"], 1):
                    content += f"   {j}. {step}\n"

                remaining_steps = len(seg["all_steps"]) - len(seg["steps"])
                if remaining_steps > 0:
                    content += f"   ... 还有{remaining_steps}个转弯\n"

                content += "\n"

            # 添加到达提示
            content += "━" * 20 + "\n\n"
            content += "📍 站点到达时间预估：\n"
            cum_time = 0
            for i, stop in enumerate(stops):
                if i == 0:
                    content += f"   • 起点 {stop}：0分钟（出发地）\n"
                else:
                    cum_time += segments[i-1]["duration"]
                    content += f"   • 到达 {stop}：约{cum_time//60}分钟\n"

            content += "\n💡 提示：\n"
            content += "• 可说「从火车站到西湖的公交」查看公交方案\n"
            content += "• 可说「从西湖步行到汉堡店」查看步行路线"

            return {"content": content, "source": "通勤助手"}

        except Exception as e:
            return {"content": f"多站点路线规划失败: {str(e)}", "source": "通勤助手"}

    def _get_route_segment(self, origin, destination, origin_name, dest_name):
        """获取单段路线的详细信息"""
        try:
            url = f"{self.base_url}/direction/driving"
            params = {
                "key": self.api_key,
                "origin": origin,
                "destination": destination,
                "output": "json"
            }

            response = requests.get(url, params=params, timeout=10)
            result = response.json()

            if result.get("status") == "1" and result.get("route", {}).get("paths"):
                path = result["route"]["paths"][0]
                distance = int(path.get("distance", 0))
                duration = int(path.get("duration", 0))
                steps = []

                for step in path.get("steps", []):
                    instruction = step.get("instruction", "")
                    if instruction:
                        steps.append(instruction)

                return {
                    "distance": distance,
                    "duration": duration,
                    "steps": steps
                }
        except Exception:
            pass
        return None

    def poi_search_nearby(self, location, keywords, radius=2000):
        """
        在指定位置附近搜索POI
        使用高德地图的"周边搜索"API
        返回距离最近的几个结果
        """
        try:
            # 解析位置坐标
            parts = location.split(',')
            if len(parts) != 2:
                return []

            lat, lon = float(parts[1]), float(parts[0])

            # 提取关键词
            keyword_list = [keywords]

            # 构建API请求
            url = f"{self.base_url}/place/around"
            params = {
                "key": self.api_key,
                "keywords": "|".join(keyword_list),
                "location": location,  # "经度,纬度" 格式
                "radius": str(radius),
                "offset": 5,
                "page": 1,
                "extensions": "all",
                "output": "json"
            }

            resp = requests.get(url, params=params, timeout=10)
            result = resp.json()

            if result.get("status") == "1" and result.get("pois"):
                pois = result["pois"]
                return pois

            # 如果周边API失败，回退到文本搜索
            url2 = f"{self.base_url}/place/text"
            params2 = {
                "key": self.api_key,
                "keywords": keywords,
                "city": "杭州",
                "output": "json"
            }
            resp2 = requests.get(url2, params=params2, timeout=10)
            result2 = resp2.json()

            if result2.get("status") == "1" and result2.get("pois"):
                pois = result2["pois"][:5]
                return pois

        except Exception as e:
            print(f"[DEBUG] 附近搜索失败: {e}")
        return []


def is_commute_request(question):
    """判断是否为通勤助手相关请求"""
    if not question:
        return False
    keywords = [
        "通勤", "路线", "怎么走", "导航", "附近",
        "公交", "驾车", "开车", "步行", "走路",
        "搜索", "在哪里", "距离", "多远",
    ]
    question_lower = question.lower()
    for kw in keywords:
        if kw in question_lower or kw in question:
            return True
    # 匹配 "从A到B" 格式
    if re.search(r"从.+到", question):
        return True
    return False


# 全局单例，供 index.py 直接调用
commute_helper = CommuteHelper()