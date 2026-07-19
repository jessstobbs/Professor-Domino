package com.wisedom.professordomino;

final class Quote {
    final String text;
    final String author;

    Quote(String text, String author) {
        this.text = text;
        this.author = author;
    }

    String displayText() {
        if (author == null || author.isEmpty()) {
            return text;
        }
        return text + "\n- " + author;
    }
}
