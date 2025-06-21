List<String> getMCQOptions(List<dynamic> data){
  if (data.length == 2){
    if (data.contains("Up") && data.contains("Down")) {
      data.sort((a, b) => a == "Up" ? -1 : 1);
    } else if (data.contains("Left") && data.contains("Right")) {
      data.sort((a, b) => a == "Left" ? -1 : 1);
    }
    return List<String>.from(data);
  }

  return List<String>.from(data)..shuffle();
}