package com.chungwoo.zerowaste.utils;

import com.google.cloud.firestore.GeoPoint;

public class GeoUtils {
    private static final double EARTH_RADIUS_M = 6371000;
    private static final double TRUST_THRESHOLD_METERS = 40.0;

    public static double haversine(double lat1, double lng1, double lat2, double lng2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_M * c; //미터
    }

    public static GeoPoint determineTrustedLocation(
            double gpsLat, double gpsLng, double selectedLat, double selectedLng) {

        double distance = haversine(gpsLat, gpsLng, selectedLat, selectedLng);

        if (distance < TRUST_THRESHOLD_METERS) {
            return new GeoPoint(selectedLat, selectedLng);
        } else {
            return new GeoPoint(gpsLat, gpsLng);
        }
    }


    public static BoundingBox calculateBoundingBox(double lat, double lng, double radiusInMeter){
        double latRadius = Math.toDegrees(radiusInMeter / EARTH_RADIUS_M);

        double lngRadius = Math.toDegrees(radiusInMeter / (EARTH_RADIUS_M * Math.cos(Math.toRadians(lat))));

        double minLat = lat - latRadius;
        double maxLat = lat + latRadius;
        double minLng = lng - lngRadius;
        double maxLng = lng + lngRadius;

        return new BoundingBox(minLat, maxLat, minLng, maxLng);
    }

    public record BoundingBox(double minLat, double maxLat, double minLng, double maxLng) {}
}
