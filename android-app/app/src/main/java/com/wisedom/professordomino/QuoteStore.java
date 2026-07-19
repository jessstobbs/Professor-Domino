package com.wisedom.professordomino;

import android.content.Context;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

final class QuoteStore {
    private final List<Quote> quotes = new ArrayList<>();
    private final Random random = new Random();

    QuoteStore(Context context) {
        load(context);
    }

    Quote randomQuote() {
        if (quotes.isEmpty()) {
            return new Quote("Add a few quotes and I will keep you company.", null);
        }
        return quotes.get(random.nextInt(quotes.size()));
    }

    private void load(Context context) {
        try (InputStream stream = context.getResources().openRawResource(R.raw.quotes);
             BufferedReader reader = new BufferedReader(new InputStreamReader(stream, StandardCharsets.UTF_8))) {
            StringBuilder builder = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                builder.append(line);
            }

            JSONArray array = new JSONArray(builder.toString());
            for (int index = 0; index < array.length(); index++) {
                JSONObject object = array.getJSONObject(index);
                String author = object.isNull("author") ? null : object.optString("author", null);
                quotes.add(new Quote(object.optString("text", ""), author));
            }
        } catch (Exception ignored) {
            quotes.add(new Quote("Begin anywhere.", "John Cage"));
            quotes.add(new Quote("Small steps still move the whole day.", null));
        }
    }
}
