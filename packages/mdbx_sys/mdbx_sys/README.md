# mdbx_sys

Rust binding of mdbx.

## Build Setup (for Windows)

For triplet `x86_64-pc-windows-msvc`

1. Install rust to use triplet `x86_64-pc-windows-msvc`.

2. Install [MSYS2](https://www.msys2.org/).

- Make sure to add `msys\usr\bin` to environment variable `PATH`.

3. Use MSYS2 package manager to install neccessary build tools:

   ```{bash}
   pacman -S --needed make
   ```

- Make sure to add `msys\mingw64\bin` to environment variable `PATH`.

3. Install `clang <= 15.0` (as a workaround for [#2500](https://github.com/rust-lang/rust-bindgen/issues/2500#issuecomment-1640545912)) from [llvm-project](https://github.com/llvm/llvm-project/releases/tag/llvmorg-15.0.7).

- Make sure to add `path\to\bin\libclang.dll` to environment variable `LIBCLANG_PATH`.
- Make sure option `MSVC` is selected when installing `Desktop Development with C++` build tool by using [Visual Studio Build Tools 2019](https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=BuildTools&rel=16)

5. Install [CMake](https://cmake.org/download/), and configure enivronment variable.

6. Restart VCCode instance to reload the environment variables. Then, build the library, and it should be successfully build 😀!

<!-- [Broken] For triplet `x86_64-pc-windows-gnu`
1. Install rust to use triplet `x86_64-pc-windows-gnu`.

2. Install [MSYS2](https://www.msys2.org/).

- Make sure to add `msys\usr\bin` to environment variable `PATH`.

3. Use MSYS2 package manager to install neccessary build tools:

   ```{bash}
   pacman -S --needed make mingw-w64-x86_64-cmake mingw-w64-x86_64-rust mingw-w64-x86-64-clang
   ```

- Make sure to add `msys\mingw64\bin` to environment variable `PATH`.
- Make sure to add `path\to\bin\libclang.dll` to environment variable `LIBCLANG_PATH`.

4. Restart VCCode instance to reload the environment variables. Then, build the library, and it should be successfully build 😀! -->

## Other Unix/Linux-Based OS

1. Install `build-essential` and `clang >= 5.0` [bindgen requirements](https://rust-lang.github.io/rust-bindgen/requirements.html).
2. Build the library, and it should be successfully build 😀!
