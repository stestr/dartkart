part of dartkart.core;

/**
 * An event emitted by a [PropertyObservable] if the value of a property
 * changes.
 */
class PropertyChangeEvent {
  /// the source object where the property was changed
  final Object source;
  /// the property name
  final String name;
  /// the old value
  final oldValue;
  ///  the new value
  final newValue;
  const PropertyChangeEvent(this.source, this.name, this.oldValue, this.newValue);

  String toString() =>
      "{PropertyChangeEvent: source=$source name=$name, oldValue=$oldValue"
      " newValue=$newValue";
}

class PropertyObservable {
  final StreamController _controller = new StreamController();

  Stream<PropertyChangeEvent> get onPropertyChanged =>
      _controller.stream;

  notify(source, String property, oldValue, newValue) =>
    _controller.sink.add(
        new PropertyChangeEvent(source, property, oldValue,newValue)
    );
}

