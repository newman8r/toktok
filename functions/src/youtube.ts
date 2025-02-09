import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as cloudinary from "cloudinary";
import * as os from "os";
import * as path from "path";
import {exec} from "child_process";
import {promisify} from "util";

const execAsync = promisify(exec);

interface VideoFormat {
  format_id: string;
  ext: string;
  filesize: number;
  acodec: string;
  vcodec: string;
}

// Initialize Cloudinary
cloudinary.v2.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Function to get video info
export const getVideoInfo = onRequest(async (request, response) => {
  try {
    const {url} = request.query;

    if (!url || typeof url !== "string") {
      response.status(400).json({
        status: "error",
        message: "Missing or invalid YouTube URL",
      });
      return;
    }

    logger.info("Fetching video info for:", url);

    const {stdout} = await execAsync(`yt-dlp -J ${url}`);
    const videoInfo = JSON.parse(stdout);

    response.json({
      status: "success",
      data: {
        title: videoInfo.title,
        duration: videoInfo.duration,
        thumbnail: videoInfo.thumbnail,
        formats: videoInfo.formats.map((f: VideoFormat) => ({
          format_id: f.format_id,
          ext: f.ext,
          filesize: f.filesize,
          acodec: f.acodec,
          vcodec: f.vcodec,
        })),
      },
    });
  } catch (error: unknown) {
    logger.error("Error fetching video info:", error);
    const errorMsg = error instanceof Error ? error.message : "Unknown error";
    response.status(500).json({
      status: "error",
      message: errorMsg,
    });
  }
});

// Function to download video
export const downloadVideo = onRequest(async (request, response) => {
  try {
    const {url, format = "best"} = request.body;

    if (!url) {
      response.status(400).json({
        status: "error",
        message: "Missing YouTube URL",
      });
      return;
    }

    logger.info("Starting video download for:", url);

    const tempDir = os.tmpdir();
    const tempFilePath = path.join(tempDir, `download-${Date.now()}.mp4`);

    await execAsync(`yt-dlp -f ${format} -o "${tempFilePath}" ${url}`);

    logger.info("Video downloaded, uploading to Cloudinary...");

    const result = await cloudinary.v2.uploader.upload(tempFilePath, {
      resource_type: "video",
      folder: "toktok_videos",
    });

    response.json({
      status: "success",
      data: {
        cloudinaryUrl: result.secure_url,
        publicId: result.public_id,
      },
    });
  } catch (error: unknown) {
    logger.error("Error downloading video:", error);
    const errorMsg = error instanceof Error ? error.message : "Unknown error";
    response.status(500).json({
      status: "error",
      message: errorMsg,
    });
  }
});

// Function to download audio only
export const downloadAudio = onRequest(async (request, response) => {
  try {
    const {url} = request.body;

    if (!url) {
      response.status(400).json({
        status: "error",
        message: "Missing YouTube URL",
      });
      return;
    }

    logger.info("Starting audio download for:", url);

    const tempDir = os.tmpdir();
    const tempFilePath = path.join(tempDir, `audio-${Date.now()}.mp3`);

    await execAsync(
      `yt-dlp -x --audio-format mp3 -o "${tempFilePath}" ${url}`
    );

    logger.info("Audio downloaded, uploading to Cloudinary...");

    const result = await cloudinary.v2.uploader.upload(tempFilePath, {
      resource_type: "video", // Cloudinary uses "video" for audio files too
      folder: "toktok_audio",
    });

    response.json({
      status: "success",
      data: {
        cloudinaryUrl: result.secure_url,
        publicId: result.public_id,
      },
    });
  } catch (error: unknown) {
    logger.error("Error downloading audio:", error);
    const errorMsg = error instanceof Error ? error.message : "Unknown error";
    response.status(500).json({
      status: "error",
      message: errorMsg,
    });
  }
});
