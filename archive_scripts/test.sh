cd ai-fastapi
source venv/bin/activate
uvicorn main:app --port 8000 &
FASTAPI_PID=$!
cd ../backend-node
node app.js &
NODE_PID=$!
sleep 3
node test_all.js > test_results.txt 2>&1
kill $FASTAPI_PID
kill $NODE_PID
cat test_results.txt
