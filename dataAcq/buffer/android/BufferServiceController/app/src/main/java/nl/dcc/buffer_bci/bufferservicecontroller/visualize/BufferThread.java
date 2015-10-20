package nl.dcc.buffer_bci.bufferservicecontroller.visualize;

import android.util.Log;
import nl.fcdonders.fieldtrip.bufferclient.BufferClientClock;
import nl.fcdonders.fieldtrip.bufferclient.BufferEvent;
import nl.fcdonders.fieldtrip.bufferclient.SamplesEventsCount;

import java.io.IOException;
import java.util.Arrays;

/**
 * Created by pieter on 18-5-15.
 */
public class BufferThread extends Thread {

    private static final String TAG = BufferThread.class.getSimpleName();
    private String host;
    private String feedbackEventType="alphaLat";
    private int timeout_ms=1000;
    private int port;
    private BufferClientClock C;
    private boolean run;

    private BufferEvent lastEvent;
    private float[] values;

    public BufferThread(String host, int port) {
        this.host = host;
        this.port = port;
        C = new BufferClientClock();
    }

    public BufferThread(String host, int port, String feedbackEventType) {
        this.host = host;
        this.port = port;
        this.feedbackEventType = feedbackEventType;
        C = new BufferClientClock();
    }

    public float[] getValues() {
        // todo use shared memory
        if (values != null) return values;
        else return new float[]{0.f, 0.f, 0.f, 0.f};
    }

    private boolean connect() {
        if (!C.isConnected()) {
            try {
                C.connect(host, port);
                //C.setAutoReconnect(true);
            } catch (IOException e) {
            }
        }
        return C.isConnected();
    }

    public void setRunning(boolean b) {
        run = b;
    }

    public void run() {
        int eventCount = 0;
        while (run) {
            if (connect()) {
                BufferEvent[] events=null;
                try {
                    // wait and block until an update event is received
                    SamplesEventsCount count = C.waitForEvents(eventCount, timeout_ms);
                    // get any new events
                    if ( count.nEvents > eventCount ) {
                        events = C.getEvents(eventCount, count.nEvents - 1);
                        eventCount = count.nEvents;
                    }
                } catch (IOException e) {
                    events = null;
                }

                if ( events != null && events.length > 0 ) {
                    // check which of these events we care about
                    for (int i = events.length - 1; i >= 0; i--) {
                        String type = String.valueOf(events[i].getType());
                        if (type.equals(feedbackEventType)) {
                            lastEvent = events[i];
                            values = convertToFloatArray(lastEvent.getValue().getArray());
                            Log.d(TAG, feedbackEventType + ": " + Arrays.toString(values));
                        }
                    }
                }
            }
        }
    }

    private float[] convertToFloatArray(Object o) {
        float[] newValues;
        if (o instanceof float[])
            newValues = (float[]) lastEvent.getValue().getArray();
        else if (o instanceof double[]) {
            double[] doubleValues = (double[]) o;
            newValues = new float[doubleValues.length];
            for (int j = 0; j < doubleValues.length; j++)
                newValues[j] = (float) doubleValues[j];
        } else {
            Log.w(TAG, "Unknown data type: " + o.getClass().toString());
            newValues = new float[]{};
        }
        return newValues;
    }
}