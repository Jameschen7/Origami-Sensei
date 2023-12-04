### develop
# echo "develop on localhost"
# python -m flask --app display run --port 8891 --debug --with-threads

### develop & Externally Visible Server
echo "develop on Externally Visible Server"
python -m flask --app display run --host=0.0.0.0 --debug --with-threads

# ### test & Externally Visible Server
# echo "test on Externally Visible Server"
# python -m flask --app display run --host=0.0.0.0 --with-threads