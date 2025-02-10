declare module "yt-dlp-wrap" {
  /**
   * YTDlpWrap class for interacting with yt-dlp
   */
  export class YTDlpWrap {
    constructor(ytDlpBinary?: string);

    getVideoInfo(url: string): Promise<unknown>;
    exec(args: string[]): Promise<void>;

    // Add more methods as needed
  }
}
