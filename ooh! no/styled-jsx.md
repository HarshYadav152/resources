```bash
"use client";

export default function BadSyntax() {
  return (
    <>
      <div className="box">Content</div>
      
      {/* WRONG: Missing backticks around CSS */}
      <style jsx>
        .box {
          color: red;
          font-size: 20px;
        }
      </style>
    </>
  );
}
```

believe me it cause error you feels why literraly why!
