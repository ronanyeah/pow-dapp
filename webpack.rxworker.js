const webpack = require("webpack");
const { resolve } = require("path");

const publicFolder = resolve("./public");

module.exports = (env) => {
  const devMode = Boolean(env.WEBPACK_SERVE);

  return {
    mode: devMode ? "development" : "production",
    entry: "./src/rxworker.ts",
    output: {
      path: publicFolder,
      filename: "rxworker.js",
    },
    stats: devMode ? "errors-warnings" : "normal",
    infrastructureLogging: {
      level: "warn",
    },
    module: {
      rules: [
        {
          test: /\.ts$/,
          use: "ts-loader",
          exclude: /node_modules/,
        },
      ],
    },
    resolve: {
      extensions: [".ts", ".js"],
    },
    plugins: [new webpack.NoEmitOnErrorsPlugin()],
  };
};
