#!/usr/bin/env bun

/**
 * Transcribe audio files using Google Gemini API.
 * Usage: bun transcribe.ts <audio-file-path>
 * Returns transcription text to stdout.
 */

import { readFile, unlink } from "fs/promises";
import { execSync } from "child_process";
import { basename, join, dirname } from "path";

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
if (!GEMINI_API_KEY) {
  console.error("Error: GEMINI_API_KEY not set");
  process.exit(1);
}

const inputPath = process.argv[2];
if (!inputPath) {
  console.error("Usage: bun transcribe.ts <audio-file-path>");
  process.exit(1);
}

const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`;

async function convertToWav(inputPath: string): Promise<string> {
  const outputPath = join(dirname(inputPath), `${basename(inputPath, "." + inputPath.split(".").pop())}.wav`);
  try {
    execSync(`/usr/bin/ffmpeg -y -i "${inputPath}" -ar 16000 -ac 1 -f wav "${outputPath}" 2>/dev/null`);
    return outputPath;
  } catch (e) {
    return inputPath;
  }
}

async function transcribe(audioPath: string): Promise<string> {
  const wavPath = await convertToWav(audioPath);
  const audioData = await readFile(wavPath);
  const base64Audio = audioData.toString("base64");

  const ext = wavPath.split(".").pop()?.toLowerCase();
  const mimeMap: Record<string, string> = {
    wav: "audio/wav",
    mp3: "audio/mp3",
    ogg: "audio/ogg",
    oga: "audio/ogg",
    m4a: "audio/mp4",
    webm: "audio/webm",
    flac: "audio/flac",
  };
  const mimeType = mimeMap[ext || ""] || "audio/wav";

  const response = await fetch(GEMINI_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            {
              inline_data: {
                mime_type: mimeType,
                data: base64Audio,
              },
            },
            {
              text: "Transcribe this audio message exactly as spoken. Output ONLY the transcription, nothing else. If the audio is in Spanish, transcribe in Spanish. If in English, transcribe in English. Preserve the original language.",
            },
          ],
        },
      ],
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Gemini API error ${response.status}: ${error}`);
  }

  const result = await response.json();
  const text = result?.candidates?.[0]?.content?.parts?.[0]?.text;

  if (wavPath !== audioPath) {
    await unlink(wavPath).catch(() => {});
  }

  if (!text) {
    throw new Error("No transcription returned from Gemini");
  }

  return text.trim();
}

try {
  const text = await transcribe(inputPath);
  console.log(text);
} catch (e: any) {
  console.error(`Transcription error: ${e.message}`);
  process.exit(1);
}
