import 'package:daily_inc/src/views/widgets/graph_style_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors fl_chart's nearest-spot search (`getNearestTouchedSpot`) so the
/// touch rule can be exercised without pumping a chart widget.
int? nearestSpotIndex(
  List<double> spotPixelXs,
  double touchX,
  double Function(Offset, Offset) distanceCalculator,
  double threshold,
) {
  int? best;
  double? smallest;
  for (var i = 0; i < spotPixelXs.length; i++) {
    final distance =
        distanceCalculator(Offset(touchX, 0), Offset(spotPixelXs[i], 0));
    if (distance <= threshold) {
      if (smallest == null || distance < smallest) {
        smallest = distance;
        best = i;
      }
    }
  }
  return best;
}

double defaultXDistance(Offset touch, Offset spot) =>
    (touch.dx - spot.dx).abs();

int? selectDay(List<double> spotPixelXs, double touchX) => nearestSpotIndex(
      spotPixelXs,
      touchX,
      GraphStyleHelpers.dayBandTouchDistance,
      double.infinity,
    );

void main() {
  // Seven daily spots laid out across a 350px wide chart.
  const chartWidth = 350.0;
  const dayCount = 7;
  const bandWidth = chartWidth / (dayCount - 1);
  final spotXs = List<double>.generate(dayCount, (i) => i * bandWidth);

  test('the old rule missed the middle of a day bar entirely', () {
    final touchX = (spotXs[2] + spotXs[3]) / 2;

    expect(nearestSpotIndex(spotXs, touchX, defaultXDistance, 10), isNull);
  });

  test('touch in the middle of a day bar selects that day', () {
    expect(selectDay(spotXs, (spotXs[2] + spotXs[3]) / 2), 3);
  });

  test('touch just right of a day bar start selects that day', () {
    expect(selectDay(spotXs, spotXs[2] + 1), 3);
  });

  test('touch on a spot selects that spot, not the next day', () {
    expect(selectDay(spotXs, spotXs[3]), 3);
  });

  test('touch inside the first bar selects the second day', () {
    expect(selectDay(spotXs, spotXs[0] + bandWidth / 2), 1);
  });

  test('touch left of the first spot selects the first day', () {
    expect(selectDay(spotXs, spotXs[0] - 5), 0);
  });

  test('touch past the last spot selects the last day', () {
    expect(selectDay(spotXs, spotXs.last + 5), dayCount - 1);
  });

  test('narrow bands still resolve to the touched day', () {
    // Two years of daily spots squeezed into 350px: well under a pixel each.
    final dense = List<double>.generate(730, (i) => i * (chartWidth / 729));
    final band = chartWidth / 729;

    expect(selectDay(dense, dense[500] + band / 2), 501);
  });
}
