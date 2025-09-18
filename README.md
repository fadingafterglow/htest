<h1>Installation</h1>
<ol>
  <li>Download the test runner <code>htest</code></li>
  <li>Move it to a folder included into your OS %PATH% (e.g. <code>...\ghcup\bin\</code>)</li>
</ol>

<h1>Test cases files</h1>
<ul>
  <li>Filename - name of the function</li>
  <li>Every test case consists of 2 lines: first line - arguments, second line - result</li>
  <li>Lines are passed directly to GHCi without additional processing</li>
  <li>Use #/ at the beginning of a line to create a comment</li>
  <li>Use #import at the beginning of a line to load an additional module</li>
</ul>

<h1>Usage</h1>
<p>
  Run <code>htest ModuleName file1 [file2 ...]</code> in the folder with your Haskell module. <br>
  Example: <code>htest Task01 .\01\*.txt</code>
</p>
