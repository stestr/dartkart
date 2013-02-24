part of dartkart.core;

class PropertyChangeEvent {
  /// the property name 
  final String name;
  /// the old value 
  final oldValue;
  ///  the new value 
  final newValue;
  const PropertyChangeEvent(this.name, this.oldValue, this.newValue);

  String toString() => "{PropertyChangeEvent: name=$name, oldValue=$oldValue"
      " newValue=$newValue";
}

class PropertyObservable {
  final StreamController _controller = new StreamController();
  
  Stream<PropertyChangeEvent> get onPropertyChanged =>
      _controller.stream;
  
  notify(String property, oldValue, newValue) =>
    _controller.sink.add(new PropertyChangeEvent(property, oldValue,newValue));
}

