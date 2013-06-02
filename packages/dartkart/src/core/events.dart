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
  PropertyChangeEvent(this.source, this.name, this.oldValue, this.newValue);

  String toString() =>
      "{PropertyChangeEvent: source=$source name=$name, oldValue=$oldValue,"
      " newValue=$newValue";
}

/**
 * A mixin class which provides the basic infrastructure for notifying
 * clients about property changes.
 *
 * ## Example
 *     class Layer extends Object with PropertyObservable {
 *        String _name;
 *        set name(String value) {
 *           var oldValue = _name;
 *           _name = value;
 *           // notify observers about property changes
 *           notify(this, "name", oldValue, value);
 *        }
 *     }
 */
abstract class PropertyObservable {
  final StreamController<PropertyChangeEvent> _controller =
      new StreamController<PropertyChangeEvent>();
  Stream<PropertyChangeEvent> _stream;

  /**
   * the stream of property change events
   *
   * ## Example
   *
   *      // an observable with a mixed in PropertyObservable
   *      var observable = ...;
   *      // listen for property change events for the property
   *      // 'my_property'
   *      observable.onPropertyChanged
   *        .where((evt) => evt.name == "my_property")
   *        .listen((evt) => print("new value: ${evt.newValue}"));
   */
  Stream<PropertyChangeEvent> get onPropertyChanged {
    //TODO: fix this - if at least one listener is present,
    // change events are emitted, regardless of whether the
    // individual listeners are paused or not. Consequence:
    // lots of change events are possibly queued up in
    // paused listener streams. => need a custom implementation
    // of a multiplexing stream which disards events if
    // they are streamed to a disabled listener
    //
    if (_stream == null) {
      _stream = _controller.stream.asBroadcastStream();
    }
    return _stream;
  }

  /**
   * Notifies observers about an update of the property with
   * name [property] in this object. [oldValue] was replaced
   * by [newValue].
   *
   * Observers are only notified, provided [newValue] is different
   * from [oldValue] and if there is at least one listener.
   *
   */
  void notify(String property, oldValue, newValue) {
    if (oldValue == newValue) return;
    //TODO: fix me - see notes in onPropertyChanged
    if (!_controller.hasListener || _controller.isPaused) return;
    _controller.sink.add(
        new PropertyChangeEvent(this, property,oldValue,newValue)
    );
  }
}

